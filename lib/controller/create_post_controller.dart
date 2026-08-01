import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:public_pulse/view/main/main_page.dart';
import 'package:public_pulse/core/services/permission_service.dart';
import 'package:public_pulse/controller/upload_progress_controller.dart';
import 'package:public_pulse/view/upload/upload_progress_page.dart';
import 'package:public_pulse/core/repository/create_post_repository.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/core/compression/image_compressor.dart';
import 'package:public_pulse/core/compression/metadata/media_metadata.dart';
import 'package:public_pulse/model/pending_media.dart';

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
    debugPrint('🚀 [CreatePostController] ==============================');
    debugPrint('🚀 [CreatePostController] uploadPost() STARTED');
    debugPrint('🚀 [CreatePostController] ==============================');
    debugPrint('📎 Media count: ${pendingMedia.length}');
    debugPrint('📝 Caption: "${caption.value}"');
    debugPrint('📍 Location: "${location.value}"');
    debugPrint('👁️ Visibility: "${visibility.value}"');
    debugPrint('📎 Media URLs:');
    for (int i = 0; i < pendingMedia.length; i++) {
      final file = File(pendingMedia[i].originalPath);
      final exists = file.existsSync();
      final size = exists ? file.lengthSync() : -1;
      debugPrint(
        '   [$i] ${pendingMedia[i].originalPath} (exists: $exists, size: $size bytes)',
      );
    }

    if (pendingMedia.isEmpty) {
      debugPrint(
        '🔴 [CreatePostController] uploadPost() ABORTED - No media selected',
      );
      return;
    }

    isUploading.value = true;
    debugPrint('🟢 [CreatePostController] isUploading set to true');

    // Register the upload progress controller and navigate
    debugPrint(
      '📦 [CreatePostController] Registering UploadProgressController...',
    );
    final uploadCtrl = Get.put(UploadProgressController());
    debugPrint('🟢 [CreatePostController] UploadProgressController registered');

    uploadCtrl.startUpload();
    debugPrint('🟢 [CreatePostController] uploadCtrl.startUpload() called');

    debugPrint('🧭 [CreatePostController] Navigating to UploadProgressPage...');
    Get.to(() => const UploadProgressPage());

    _uploadMedia(uploadCtrl);
  }

  Future<void> _uploadMedia(UploadProgressController uploadCtrl) async {
    debugPrint('📤 [_uploadMedia] ==============================');
    debugPrint('📤 [_uploadMedia] _uploadMedia() STARTED');
    debugPrint('📤 [_uploadMedia] ==============================');

    try {
      final List<Map<String, String>> mediaItems = [];
      final List<Map<String, dynamic>> mediaFileRefs =
          []; // tracks original path + compressed File per item, in order
      final uploadStartTime = DateTime.now();
      final totalFiles = pendingMedia.length;
      debugPrint('📤 [_uploadMedia] Total files to upload: $totalFiles');

      for (int i = 0; i < totalFiles; i++) {
        debugPrint(
          '📤 [_uploadMedia] --- Processing file ${i + 1} of $totalFiles ---',
        );
        final filePath = pendingMedia[i].originalPath;
        final file = File(filePath);
        debugPrint('📤 [_uploadMedia] File path: $filePath');

        // Check if file exists
        if (!file.existsSync()) {
          debugPrint('🔴 [_uploadMedia] FILE DOES NOT EXIST: $filePath');
          throw Exception("File does not exist: $filePath");
        }
        final fileSize = file.lengthSync();
        debugPrint(
          '📤 [_uploadMedia] File size: $fileSize bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)',
        );

        final bucket = CreatePostRepository.imageBucket;
        debugPrint('📤 [_uploadMedia] Target bucket: $bucket');

        File uploadFile = file;
        uploadCtrl.updateStep(UploadStep.compressing);
        uploadCtrl.updateCurrentFile("Compressing ${i + 1} of $totalFiles");
        debugPrint('🗜️ [_uploadMedia] Compressing image: $filePath');
        final compressedFile = await imageCompressor.compressImage(filePath);
        if (compressedFile != null) {
          uploadFile = compressedFile;
          final compressedSize = compressedFile.lengthSync();
          debugPrint(
            '🗜️ [_uploadMedia] Compressed size: $compressedSize bytes (was $fileSize bytes)',
          );
        } else {
          debugPrint(
            '🟡 [_uploadMedia] Compression returned null, using original file',
          );
        }

        uploadCtrl.updateStep(UploadStep.uploading);
        uploadCtrl.updateCurrentFile("Uploading ${i + 1} of $totalFiles");
        debugPrint(
          '📤 [_uploadMedia] Updated UI: "Uploading ${i + 1} of $totalFiles"',
        );

        final originalName = uploadFile.path.split(RegExp(r'[/\\]')).last;
        final fileName =
            "${DateTime.now().millisecondsSinceEpoch}_$originalName";
        debugPrint('📤 [_uploadMedia] Original name: $originalName');
        debugPrint('📤 [_uploadMedia] Generated fileName: $fileName');

        debugPrint('📤 [_uploadMedia] Calling repository.uploadImage()...');
        final storagePath = await repository.uploadImage(
          imageFile: uploadFile,
          fileName: fileName,
          bucket: bucket,
          onProgress: (sent, total) {
            final fileProgress = sent / total;
            final overallProgress = (i + fileProgress) / totalFiles;
            uploadCtrl.updateProgress(overallProgress);

            final uploadedMB = (sent / 1024 / 1024).toStringAsFixed(2);
            final totalMB = (total / 1024 / 1024).toStringAsFixed(2);

            final elapsedSeconds =
                DateTime.now().difference(uploadStartTime).inMilliseconds /
                1000;

            if (elapsedSeconds <= 0) return;
            final speed = (sent / 1024 / 1024) / elapsedSeconds;
            final speedText = "${speed.toStringAsFixed(2)} MB/s";
            final remainingBytes = total - sent;
            final remainingSeconds = remainingBytes / (speed * 1024 * 1024);
            final remainingText = "${remainingSeconds.toStringAsFixed(0)} sec";

            uploadCtrl.updateUploadStats(
              uploaded: "$uploadedMB MB / $totalMB MB",
              speed: speedText,
              timeLeft: remainingText,
            );

            // Log progress periodically (every 5%)
            final percent = (overallProgress * 100).toInt();
            if (percent % 5 == 0) {
              debugPrint(
                '📊 [Upload Progress] File ${i + 1}/$totalFiles: $percent% - $speedText - $uploadedMB/$totalMB MB',
              );
            }
          },
        );

        debugPrint('🟢 [_uploadMedia] File ${i + 1} uploaded successfully!');
        debugPrint('🟢 [_uploadMedia] Storage path: $storagePath');

        mediaItems.add({'storage_path': storagePath, 'media_type': 'IMAGE'});
        debugPrint(
          '🟢 [_uploadMedia] Media item added: {storage_path: $storagePath, media_type: IMAGE}',
        );

        mediaFileRefs.add({
          'originalPath': filePath,
          'compressedFile': uploadFile,
        });
      }

      // Save the post to the database now that all media is uploaded
      debugPrint('💾 [_uploadMedia] ==============================');
      debugPrint(
        '💾 [_uploadMedia] All media uploaded! Now saving post to database...',
      );
      debugPrint('💾 [_uploadMedia] Total media items: ${mediaItems.length}');
      for (int i = 0; i < mediaItems.length; i++) {
        debugPrint('💾 [_uploadMedia] Media [$i]: ${mediaItems[i]}');
      }

      uploadCtrl.updateStep(UploadStep.saving);
      uploadCtrl.updateCurrentFile("Saving post...");

      debugPrint('🔍 [_uploadMedia] Fetching current profile ID...');
      final profileId = await repository.getCurrentProfileId();
      if (profileId == null) {
        debugPrint('🔴 [_uploadMedia] NO PROFILE FOUND for current user!');
        throw Exception("No profile found for current user.");
      }
      debugPrint('🟢 [_uploadMedia] Profile ID: $profileId');

      debugPrint('💾 [_uploadMedia] Calling repository.createPost()...');
      debugPrint('💾 [_uploadMedia]   profileId: $profileId');
      debugPrint(
        '💾 [_uploadMedia]   caption: ${caption.value.isEmpty ? "null" : caption.value}',
      );
      debugPrint(
        '💾 [_uploadMedia]   location: ${location.value.isEmpty ? "null" : location.value}',
      );
      debugPrint('💾 [_uploadMedia]   visibility: ${visibility.value}');
      debugPrint('💾 [_uploadMedia]   mediaItems count: ${mediaItems.length}');

      final postResult = await repository.createPost(
        profileId: profileId,
        caption: caption.value.isEmpty ? null : caption.value,
        location: location.value.isEmpty ? null : location.value,
        visibility: visibility.value,
        mediaItems: mediaItems,
      );

      final postId = postResult['post_id'] as String;
      final mediaIds = postResult['media_ids'] as List<String>;

      debugPrint('🟢 [_uploadMedia] ==============================');
      debugPrint('🟢 [_uploadMedia] POST CREATED SUCCESSFULLY!');
      debugPrint('🟢 [_uploadMedia] Post ID: $postId');
      debugPrint('🟢 [_uploadMedia] Media IDs: $mediaIds');
      debugPrint('🟢 [_uploadMedia] ==============================');

      // Extract & save metadata for each image — best-effort, never blocks post creation
      try {
        uploadCtrl.updateStep(UploadStep.metadata);
        uploadCtrl.updateCurrentFile("Saving metadata...");
        final List<Map<String, dynamic>> metadataRows = [];

        for (int i = 0; i < mediaFileRefs.length; i++) {
          final ref = mediaFileRefs[i];
          final mediaId = mediaIds[i];
          final originalPath = ref['originalPath'] as String;
          final compressedFile = ref['compressedFile'] as File;

          debugPrint(
            '📊 [_uploadMedia] Extracting metadata for mediaId=$mediaId',
          );
          final metadata = await MediaMetadataExtractor.extractImageMetadata(
            originalPath: originalPath,
            compressedFile: compressedFile,
            mediaId:
                mediaId, //--------------- review needed ------------------------
          );
          metadataRows.add(metadata);
          debugPrint('📊 [_uploadMedia] Metadata extracted: $metadata');
        }

        if (metadataRows.isNotEmpty) {
          await repository.insertMediaMetadata(metadataRows);
          debugPrint(
            '🟢 [_uploadMedia] Metadata saved for ${metadataRows.length} item(s)',
          );
        }
      } catch (e) {
        // Metadata is supplementary — never fail the whole post over this
        debugPrint(
          '🟡 [_uploadMedia] Metadata extraction/save failed (non-fatal): $e',
        );
      }

      uploadCtrl.updateStep(UploadStep.completed);
      uploadCtrl.completeUpload();
      debugPrint('🟢 [_uploadMedia] uploadCtrl.completeUpload() called');

      debugPrint('⏳ [_uploadMedia] Waiting 1 second before navigation...');
      await Future.delayed(const Duration(seconds: 1));

      debugPrint(
        '🧭 [_uploadMedia] Finding HomeController and refreshing posts...',
      );
      final homeController = Get.find<HomeController>();
      homeController.currentIndex.value = 0;
      await homeController.refreshFeed();
      debugPrint('🟢 [_uploadMedia] Posts reloaded');

      debugPrint('🧭 [_uploadMedia] Navigating to MainPage...');
      Get.offAll(() => MainPage());
      debugPrint(
        '🟢 [_uploadMedia] Navigation complete. Post creation flow finished!',
      );
    } catch (e, stackTrace) {
      debugPrint('🔴 [_uploadMedia] ==============================');
      debugPrint('🔴 [_uploadMedia] ERROR in _uploadMedia!');
      debugPrint('🔴 [_uploadMedia] Error: $e');
      debugPrint('🔴 [_uploadMedia] Error type: ${e.runtimeType}');
      debugPrint('🔴 [_uploadMedia] Stack trace:');
      debugPrint('$stackTrace');
      debugPrint('🔴 [_uploadMedia] ==============================');
      uploadCtrl.failUpload(e.toString());
      debugPrint('🔴 [_uploadMedia] uploadCtrl.failUpload() called with: $e');
    }
  }

  // Add location
  void addLocation() {
    debugPrint('📍 [CreatePostController] addLocation() called');
    // Implement location picker
    Get.snackbar(
      'Location',
      'Location picker coming soon!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Show permission error
  void _showPermissionError(String permission) {
    debugPrint('🔴 [CreatePostController] Permission error: $permission');
    Get.snackbar(
      "Permission Required",
      "Please grant $permission permission.",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void showMediaPicker() {
    debugPrint('📸 [CreatePostController] showMediaPicker() called');
    debugPrint(
      '📸 [CreatePostController] Current media count: ${pendingMedia.length}',
    );
    if (pendingMedia.length >= 10) {
      debugPrint('🟡 [CreatePostController] Media limit reached (10)');
      Get.snackbar(
        'Limit reached',
        'You can add up to 10 media items',
        snackPosition: SnackPosition.BOTTOM,
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
