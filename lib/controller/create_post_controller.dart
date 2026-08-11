import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:public_pulse/view/main/main_page.dart';
import 'package:public_pulse/core/services/permission_service.dart';
import 'package:public_pulse/core/repository/create_post_repository.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/core/compression/image_compressor.dart';
import 'package:public_pulse/core/compression/metadata/media_metadata.dart';
import 'package:public_pulse/model/pending_media.dart';
import 'package:public_pulse/widget/local/app_alert.dart';

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

  // Location
  final RxString location = ''.obs;

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
          color: Colors.red,
        );
      }
    });
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

    final List<Map<String, String>> mediaItems = [];

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

      mediaItems.add({'storage_path': storagePath, 'media_type': 'IMAGE'});

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

  // Add location
  void addLocation() {
    debugPrint('📍 [CreatePostController] addLocation() called');
    // Implement location picker
    CustomAlert.show(
      title: 'Location',
      message: 'Location picker coming soon!',
      icon: Icons.location_on_outlined,
      color: Colors.blue,
    );
  }

  // Show permission error
  void _showPermissionError(String permission) {
    debugPrint('🔴 [CreatePostController] Permission error: $permission');
    CustomAlert.show(
      title: 'Permission Required',
      message: 'Please grant $permission permission.',
      icon: Icons.lock_outline,
      color: Colors.orange,
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
        color: Colors.orange,
      );
      return;
    }
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take Photo"),
                onTap: () async {
                  debugPrint('📸 [MediaPicker] Take Photo selected');
                  Get.back();

                  final granted =
                      await PermissionService.requestCameraPermission();
                  debugPrint('📸 [MediaPicker] Camera permission: $granted');

                  if (!granted) {
                    _showPermissionError("Camera");
                    return;
                  }

                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                  );

                  if (image != null) {
                    debugPrint(
                      '📸 [MediaPicker] Photo captured: ${image.path}',
                    );
                    pendingMedia.add(PendingMedia(originalPath: image.path));
                    debugPrint(
                      '📸 [MediaPicker] Media count now: ${pendingMedia.length}',
                    );
                  } else {
                    debugPrint('🟡 [MediaPicker] Photo capture cancelled');
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

                  // image_picker handles gallery permissions internally
                  // on both Android and iOS — no manual permission check needed.
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  if (image != null) {
                    debugPrint(
                      '🖼️ [MediaPicker] Image selected: ${image.path}',
                    );
                    pendingMedia.add(PendingMedia(originalPath: image.path));
                    debugPrint(
                      '🖼️ [MediaPicker] Media count now: ${pendingMedia.length}',
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
