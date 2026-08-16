import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:public_pulse/view/main/main_page.dart';
import 'package:public_pulse/core/services/permission_service.dart';
import 'package:public_pulse/core/repository/create_post_repository.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/core/compression/image_compressor.dart';
import 'package:public_pulse/core/compression/metadata/media_metadata.dart';
import 'package:public_pulse/model/pending_media.dart';
import 'package:public_pulse/widget/local/app_alert.dart';
import 'package:public_pulse/core/services/location_service.dart';
import 'package:public_pulse/model/location_suggestion.dart';

class CreatePostController extends GetxController {
  final ImagePicker picker = ImagePicker();

  final CreatePostRepository repository = CreatePostRepository();
  final ImageCompressor imageCompressor = ImageCompressor();

  // Page controller for media carousel
  final PageController pageController = PageController();

  // Current page index
  final RxInt currentIndex = 0.obs;

  // Caption text and controller
  final TextEditingController captionController = TextEditingController();
  final RxString caption = ''.obs;
  final int captionMaxLength = 500;

  // Media items pending upload (images only)
  final RxList<PendingMedia> pendingMedia = <PendingMedia>[].obs;

  // ============================================================
  // LOCATION
  // ============================================================

  final RxString location = ''.obs;

  // Short location name shown in UI
  final RxString locationDisplayName = ''.obs;

  final LocationService locationService = LocationService();

  final TextEditingController locationSearchController =
      TextEditingController();

  final RxList<LocationSuggestion> locationSuggestions =
      <LocationSuggestion>[].obs;

  final RxBool isSearchingLocation = false.obs;

  final RxBool isGettingCurrentLocation = false.obs;

  Timer? _locationSearchDebounce;

  // Upload state
  final RxBool isUploading = false.obs;

  // Visibility
  final RxString visibility = "PUBLIC".obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('🟢 [CreatePostController] onInit called');
    captionController.addListener(() {
      caption.value = captionController.text;
    });
  }

  @override
  void onClose() {
    debugPrint('🔴 [CreatePostController] onClose called');

    _locationSearchDebounce?.cancel();

    locationSearchController.dispose();
    captionController.dispose();
    pageController.dispose();

    super.onClose();
  }

  // Navigate to a specific page
  void animateToPage(int index) {
    debugPrint('🔵 [CreatePostController] animateToPage($index)');
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Update current page index when page changes
  void onPageChanged(int index) {
    debugPrint('🔵 [CreatePostController] onPageChanged($index)');
    currentIndex.value = index;
  }

  // Remove image at index
  void removeImageAt(int index) {
    debugPrint(
      '🟡 [CreatePostController] removeImageAt($index) - total: ${pendingMedia.length}',
    );
    if (index >= 0 && index < pendingMedia.length) {
      final removed = pendingMedia[index].originalPath;
      debugPrint('🟡 [CreatePostController] Removed: $removed');
      pendingMedia.removeAt(index);
      if (currentIndex.value >= pendingMedia.length &&
          pendingMedia.isNotEmpty) {
        currentIndex.value = pendingMedia.length - 1;
      }
      debugPrint(
        '🟡 [CreatePostController] Remaining media: ${pendingMedia.length}',
      );
    } else {
      debugPrint(
        '🔴 [CreatePostController] removeImageAt($index) - INDEX OUT OF RANGE',
      );
    }
  }

  // Upload post
  void uploadPost() {
    debugPrint('🚀 [CreatePostController] uploadPost() STARTED');

    if (pendingMedia.isEmpty) {
      debugPrint('🔴 No media selected');
      return;
    }

    if (isUploading.value) {
      debugPrint('🟡 Upload already running');
      return;
    }

    isUploading.value = true;

    // ============================================================
    // SNAPSHOT EVERYTHING
    // ============================================================

    final mediaSnapshot = List<PendingMedia>.from(pendingMedia);

    final captionSnapshot = caption.value.trim().isEmpty
        ? null
        : caption.value.trim();

    final locationSnapshot = location.value.trim().isEmpty
        ? null
        : location.value.trim();

    final visibilitySnapshot = visibility.value;

    // ============================================================
    // GET HOME CONTROLLER BEFORE LEAVING PAGE
    // ============================================================

    final homeController = Get.find<HomeController>();

    // ============================================================
    // CREATE TEMPORARY POST
    // ============================================================

    final tempPostId = homeController.addUploadingPost(
      mediaSnapshot: mediaSnapshot,
      caption: captionSnapshot,
      location: locationSnapshot,
      visibility: visibilitySnapshot,
    );

    debugPrint('🟢 Temporary uploading post created: $tempPostId');

    // ============================================================
    // LEAVE CREATE POST PAGE
    // ============================================================

    Get.offAll(() => MainPage());

    // ============================================================
    // BACKGROUND UPLOAD
    // ============================================================

    Future(() async {
      try {
        await _uploadMediaInBackground(
          mediaSnapshot: mediaSnapshot,
          caption: captionSnapshot,
          location: locationSnapshot,
          visibility: visibilitySnapshot,
          tempPostId: tempPostId,
          homeController: homeController,
        );

        debugPrint('🟢 Background upload completed');
      } catch (e, stackTrace) {
        debugPrint('🔴 Background upload failed: $e');

        debugPrintStack(stackTrace: stackTrace);

        // Keep the temporary post.
        // Change it into FAILED state.
        homeController.markUploadingPostFailed(tempPostId);

        CustomAlert.show(
          title: 'Upload Failed',
          message: 'Could not upload your post. Please try again.',
          icon: Icons.cloud_off,
          color: AppColors.semanticRed,
        );
      }
    });
  }

  // ============================================================
  // IMAGE DIMENSIONS
  // ============================================================

  Future<({int width, int height})> _getImageDimensions(File file) async {
    final bytes = await file.readAsBytes();

    final codec = await ui.instantiateImageCodec(bytes);

    try {
      final frame = await codec.getNextFrame();

      try {
        return (width: frame.image.width, height: frame.image.height);
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  Future<void> _uploadMediaInBackground({
    required List<PendingMedia> mediaSnapshot,
    required String? caption,
    required String? location,
    required String visibility,
    required String tempPostId,
    required HomeController homeController,
  }) async {
    debugPrint('📤 [BackgroundUpload] STARTED');

    final List<Map<String, dynamic>> mediaItems = [];

    final List<Map<String, dynamic>> mediaFileRefs = [];

    final totalFiles = mediaSnapshot.length;

    // ============================================================
    // 1. COMPRESS + UPLOAD MEDIA
    // ============================================================

    for (int i = 0; i < totalFiles; i++) {
      final originalPath = mediaSnapshot[i].originalPath;

      final originalFile = File(originalPath);

      if (!originalFile.existsSync()) {
        throw Exception('File does not exist: $originalPath');
      }

      debugPrint(
        '🗜️ [BackgroundUpload] '
        'Compressing ${i + 1}/$totalFiles',
      );

      File uploadFile = originalFile;

      final compressedFile = await imageCompressor.compressImage(originalPath);

      if (compressedFile != null) {
        uploadFile = compressedFile;

        debugPrint(
          '🗜️ Compression successful: '
          '${compressedFile.lengthSync()} bytes',
        );
      } else {
        debugPrint(
          '🟡 Compression returned null. '
          'Using original file.',
        );
      }

      // ============================================================
      // GET ACTUAL UPLOADED IMAGE DIMENSIONS
      // ============================================================

      final dimensions = await _getImageDimensions(uploadFile);

      debugPrint(
        '📐 [BackgroundUpload] '
        'Image ${i + 1}: '
        '${dimensions.width} x ${dimensions.height}',
      );

      final originalName = uploadFile.path.split(RegExp(r'[/\\]')).last;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$originalName';

      debugPrint(
        '☁️ [BackgroundUpload] '
        'Uploading $fileName',
      );

      final storagePath = await repository.uploadImage(
        imageFile: uploadFile,
        fileName: fileName,
        bucket: CreatePostRepository.imageBucket,
        onProgress: (sent, total) {
          if (total <= 0) return;

          final percent = ((sent / total) * 100).toInt();

          if (percent % 10 == 0) {
            debugPrint(
              '☁️ [BackgroundUpload] '
              'Image ${i + 1}/$totalFiles: $percent%',
            );
          }
        },
      );

      debugPrint(
        '🟢 [BackgroundUpload] '
        'Storage upload completed: $storagePath',
      );

      mediaItems.add({
        'storage_path': storagePath,
        'media_type': 'IMAGE',
        'width': dimensions.width,
        'height': dimensions.height,
      });

      mediaFileRefs.add({
        'originalPath': originalPath,
        'compressedFile': uploadFile,
      });
    }

    // ============================================================
    // 2. GET PROFILE
    // ============================================================

    final profileId = await repository.getCurrentProfileId();

    if (profileId == null) {
      throw Exception('No profile found for current user.');
    }

    // ============================================================
    // 3. CREATE POST
    // ============================================================

    debugPrint('💾 [BackgroundUpload] Creating post...');

    final postResult = await repository.createPost(
      profileId: profileId,
      caption: caption,
      location: location,
      visibility: visibility,
      mediaItems: mediaItems,
    );

    final postId = postResult['post_id'] as String;

    final mediaIds = postResult['media_ids'] as List<String>;

    debugPrint(
      '🟢 [BackgroundUpload] '
      'Post created: $postId',
    );

    // ============================================================
    // 4. METADATA
    // ============================================================

    try {
      final List<Map<String, dynamic>> metadataRows = [];

      for (int i = 0; i < mediaFileRefs.length; i++) {
        final ref = mediaFileRefs[i];

        final metadata = await MediaMetadataExtractor.extractImageMetadata(
          originalPath: ref['originalPath'] as String,
          compressedFile: ref['compressedFile'] as File,
          mediaId: mediaIds[i],
        );

        metadataRows.add(metadata);
      }

      if (metadataRows.isNotEmpty) {
        await repository.insertMediaMetadata(metadataRows);

        debugPrint('🟢 [BackgroundUpload] Metadata saved');
      }
    } catch (e) {
      // Metadata failure should NOT delete the post.
      debugPrint(
        '🟡 [BackgroundUpload] '
        'Metadata failed: $e',
      );
    }

    // ============================================================
    // 5. REFRESH HOME
    // ============================================================

    final refreshed = await homeController.refreshFeed();

    if (!refreshed) {
      throw Exception(
        'Post uploaded successfully, '
        'but feed refresh failed.',
      );
    }

    debugPrint('🟢 [BackgroundUpload] Home feed refreshed');

    // ============================================================
    // 6. SUCCESS
    // ============================================================

    homeController.removeUploadingPost(tempPostId);

    debugPrint(
      '🟢 [BackgroundUpload] '
      'Temporary uploading post removed',
    );

    debugPrint('🟢 [BackgroundUpload] Finished successfully');
  }

  // ============================================================
  // LOCATION SEARCH
  // ============================================================

  void onLocationSearchChanged(String value) {
    _locationSearchDebounce?.cancel();

    final query = value.trim();

    debugPrint('🔎 [CreatePostController] Location query: $query');

    if (query.length < 2) {
      locationSuggestions.clear();
      isSearchingLocation.value = false;
      return;
    }

    isSearchingLocation.value = true;

    // Wait until user stops typing for 500ms
    // before calling Geoapify.
    _locationSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchLocations(query);
    });
  }

  // ============================================================
  // SEARCH GEOAPIFY
  // ============================================================

  Future<void> _searchLocations(String query) async {
    try {
      debugPrint('🔎 [CreatePostController] Searching location: $query');

      final results = await locationService.searchLocations(query);

      // Prevent old API responses from replacing
      // results for a newer search.
      final currentQuery = locationSearchController.text.trim();

      if (currentQuery != query) {
        debugPrint(
          '🟡 [CreatePostController] '
          'Ignoring outdated location result',
        );

        return;
      }

      locationSuggestions.assignAll(results);

      debugPrint(
        '🟢 [CreatePostController] '
        '${results.length} locations found',
      );
    } catch (e) {
      debugPrint(
        '🔴 [CreatePostController] '
        'Location search failed: $e',
      );

      locationSuggestions.clear();
    } finally {
      if (locationSearchController.text.trim() == query) {
        isSearchingLocation.value = false;
      }
    }
  }

  // ============================================================
  // USE CURRENT LOCATION
  // ============================================================

  Future<void> useCurrentLocation() async {
    if (isGettingCurrentLocation.value) {
      return;
    }

    isGettingCurrentLocation.value = true;

    try {
      debugPrint(
        '📍 [CreatePostController] '
        'Getting current location...',
      );

      final selected = await locationService.getCurrentLocation();

      selectLocation(selected);
    } catch (e) {
      debugPrint(
        '🔴 [CreatePostController] '
        'Current location failed: $e',
      );

      final message = e.toString().replaceFirst('Exception: ', '');

      CustomAlert.show(
        title: 'Location Error',
        message: message,
        icon: Icons.location_off_outlined,
        color: AppColors.semanticOrange,
      );
    } finally {
      isGettingCurrentLocation.value = false;
    }
  }

  // ============================================================
  // SELECT LOCATION
  // ============================================================

  void selectLocation(LocationSuggestion selected) {
    debugPrint(
      '📍 [CreatePostController] '
      'Selected location name: ${selected.name}',
    );

    debugPrint(
      '📍 [CreatePostController] '
      'Selected full address: ${selected.formattedAddress}',
    );

    // Full address → database
    location.value = selected.formattedAddress;

    // Short name → UI
    locationDisplayName.value = selected.name;

    _locationSearchDebounce?.cancel();

    locationSuggestions.clear();

    locationSearchController.clear();

    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
  }

  // ============================================================
  // CLEAR SELECTED LOCATION
  // ============================================================

  void clearLocation() {
    debugPrint('📍 [CreatePostController] Location cleared');

    location.value = '';
    locationDisplayName.value = '';
  }

  // ============================================================
  // RESET LOCATION PICKER
  // ============================================================

  void resetLocationPicker() {
    debugPrint(
      '📍 [CreatePostController] '
      'Resetting location picker',
    );

    _locationSearchDebounce?.cancel();

    locationSearchController.clear();

    locationSuggestions.clear();

    isSearchingLocation.value = false;
  }

  // Show permission error
  void _showPermissionError(String permission) {
    debugPrint('🔴 [CreatePostController] Permission error: $permission');
    CustomAlert.show(
      title: 'Permission Required',
      message: 'Please grant $permission permission.',
      icon: Icons.lock_outline,
      color: AppColors.semanticOrange,
    );
  }

  void showMediaPicker() {
    debugPrint('📸 [CreatePostController] showMediaPicker() called');
    debugPrint(
      '📸 [CreatePostController] Current media count: ${pendingMedia.length}',
    );
    if (pendingMedia.length >= 10) {
      debugPrint('🟡 [CreatePostController] Media limit reached (10)');
      CustomAlert.show(
        title: 'Limit reached',
        message: 'You can add up to 10 media items',
        icon: Icons.info_outline,
        color: AppColors.semanticOrange,
      );
      return;
    }
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose Photos from Gallery"),
                onTap: () async {
                  debugPrint(
                    '🖼️ [MediaPicker] Choose Photos from Gallery selected',
                  );

                  Get.back();

                  // ==========================================================
                  // GALLERY PERMISSION
                  // ==========================================================

                  final granted =
                      await PermissionService.requestGalleryPermission();

                  debugPrint('🖼️ [MediaPicker] Gallery permission: $granted');

                  if (!granted) {
                    _showPermissionError('Gallery');
                    return;
                  }

                  // ==========================================================
                  // AVAILABLE SLOTS
                  // ==========================================================

                  final remainingSlots = 10 - pendingMedia.length;

                  if (remainingSlots <= 0) {
                    CustomAlert.show(
                      title: 'Limit Reached',
                      message: 'You can add up to 10 photos.',
                      icon: Icons.info_outline,
                      color: AppColors.semanticOrange,
                    );

                    return;
                  }

                  // ==========================================================
                  // MULTIPLE IMAGE PICKER
                  // ==========================================================

                  final List<XFile> images = await picker.pickMultiImage();

                  if (images.isEmpty) {
                    debugPrint('🟡 [MediaPicker] Image selection cancelled');
                    return;
                  }

                  debugPrint(
                    '🖼️ [MediaPicker] '
                    '${images.length} images selected',
                  );

                  // ==========================================================
                  // KEEP MAXIMUM 10 PHOTOS
                  // ==========================================================

                  final selectedImages = images.take(remainingSlots).toList();

                  pendingMedia.addAll(
                    selectedImages.map(
                      (image) => PendingMedia(originalPath: image.path),
                    ),
                  );

                  // Start carousel from first selected image.
                  currentIndex.value = 0;

                  debugPrint(
                    '🖼️ [MediaPicker] '
                    '${selectedImages.length} images added',
                  );

                  debugPrint(
                    '🖼️ [MediaPicker] '
                    'Total media count: ${pendingMedia.length}',
                  );

                  // User selected more than available slots.
                  if (images.length > remainingSlots) {
                    CustomAlert.show(
                      title: 'Photo Limit',
                      message:
                          'Only $remainingSlots photos were added. '
                          'You can add up to 10 photos.',
                      icon: Icons.info_outline,
                      color: AppColors.semanticOrange,
                    );
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose Image from Gallery"),
                onTap: () async {
                  debugPrint(
                    '🖼️ [MediaPicker] Choose Image from Gallery selected',
                  );

                  Get.back();

                  // ==========================================================
                  // REAL ANDROID GALLERY PERMISSION
                  // ==========================================================

                  final granted =
                      await PermissionService.requestGalleryPermission();

                  debugPrint('🖼️ [MediaPicker] Gallery permission: $granted');

                  if (!granted) {
                    _showPermissionError('Gallery');
                    return;
                  }

                  // ==========================================================
                  // OPEN GALLERY
                  // ==========================================================

                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  if (image != null) {
                    debugPrint(
                      '🖼️ [MediaPicker] Image selected: ${image.path}',
                    );

                    pendingMedia.add(PendingMedia(originalPath: image.path));

                    debugPrint(
                      '🖼️ [MediaPicker] Media count now: '
                      '${pendingMedia.length}',
                    );
                  } else {
                    debugPrint('🟡 [MediaPicker] Image selection cancelled');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
