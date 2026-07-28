import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:public_pulse/core/services/permission_service.dart';
import 'package:public_pulse/controller/upload_progress_controller.dart';
import 'package:public_pulse/view/upload/upload_progress_page.dart';

class CreatePostController extends GetxController {
  final ImagePicker picker = ImagePicker();

  // Page controller for media carousel
  final PageController pageController = PageController();

  // Current page index
  final RxInt currentIndex = 0.obs;

  // Caption text and controller
  final TextEditingController captionController = TextEditingController();
  final RxString caption = ''.obs;
  final int captionMaxLength = 500;

  // Media URLs (images/videos)
  final RxList<String> mediaUrls = <String>[].obs;

  // Location
  final RxString location = ''.obs;

  // Upload state
  final RxBool isUploading = false.obs;

  // Visibility
  final RxString visibility = "PUBLIC".obs;

  @override
  void onInit() {
    super.onInit();
    captionController.addListener(() {
      caption.value = captionController.text;
    });
  }

  @override
  void onClose() {
    captionController.dispose();
    pageController.dispose();
    super.onClose();
  }

  // Navigate to a specific page
  void animateToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Update current page index when page changes
  void onPageChanged(int index) {
    currentIndex.value = index;
  }

  // Remove image at index
  void removeImageAt(int index) {
    if (index >= 0 && index < mediaUrls.length) {
      mediaUrls.removeAt(index);
      if (currentIndex.value >= mediaUrls.length && mediaUrls.isNotEmpty) {
        currentIndex.value = mediaUrls.length - 1;
      }
    }
  }

  // Upload post
  void uploadPost() {
    if (mediaUrls.isEmpty) return;
    isUploading.value = true;

    // Determine if the post has videos
    final hasVideos = mediaUrls.any((u) => u.toLowerCase().endsWith('.mp4'));

    // Register the upload progress controller and navigate
    final uploadCtrl = Get.put(UploadProgressController());
    uploadCtrl.startSimulatedUpload(mediaUrls.length, fileType: hasVideos ? 'video' : 'image');

    Get.to(() => const UploadProgressPage());
  }

  // Add location
  void addLocation() {
    // Implement location picker
    Get.snackbar(
      'Location',
      'Location picker coming soon!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Show permission error
  void _showPermissionError(String permission) {
    Get.snackbar(
      "Permission Required",
      "Please grant $permission permission.",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void showMediaPicker() {
    if (mediaUrls.length >= 10) {
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
                  Get.back();

                  final granted =
                      await PermissionService.requestCameraPermission();

                  if (!granted) {
                    _showPermissionError("Camera");
                    return;
                  }

                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                  );

                  if (image != null) {
                    mediaUrls.add(image.path);
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text("Take Video"),
                onTap: () async {
                  Get.back();

                  final granted =
                      await PermissionService.requestCameraPermission();

                  if (!granted) {
                    _showPermissionError("Camera");
                    return;
                  }

                  final XFile? video = await picker.pickVideo(
                    source: ImageSource.camera,
                  );

                  if (video != null) {
                    if (isClosed) return;
                    mediaUrls.add(video.path);
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose Image from Gallery"),
                onTap: () async {
                  Get.back();

                  final granted =
                      await PermissionService.requestGalleryPermission();

                  if (!granted) {
                    _showPermissionError("Gallery");
                    return;
                  }

                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  if (image != null) {
                    mediaUrls.add(image.path);
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text("Choose Video from Gallery"),
                onTap: () async {
                  Get.back();

                  final granted =
                      await PermissionService.requestGalleryPermission();

                  if (!granted) {
                    _showPermissionError("Gallery");
                    return;
                  }

                  final XFile? video = await picker.pickVideo(
                    source: ImageSource.gallery,
                  );

                  if (video != null) {
                    mediaUrls.add(video.path);
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
