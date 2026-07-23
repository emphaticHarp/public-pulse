import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/controller/create_post_controller.dart';

/// Builds an image widget that handles both local file paths and network URLs.
Widget _buildMediaImage(String path, BoxFit fit) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return Image.network(
      path,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.gray100,
        child: const Icon(
          Icons.broken_image,
          color: AppColors.gray400,
          size: 48,
        ),
      ),
    );
  }
  return Image.file(
    File(path),
    fit: fit,
    errorBuilder: (context, error, stackTrace) => Container(
      color: AppColors.gray100,
      child: const Icon(Icons.broken_image, color: AppColors.gray400, size: 48),
    ),
  );
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------
class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CreatePostController controller = Get.find<CreatePostController>();

    return PopScope(
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) {
      Get.delete<CreatePostController>();
    }
  },
child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448), // max-w-md
            child: Column(
              children: [
                const _Header(),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MediaCarousel(controller: controller),
                            const _InfoBanner(),
                            _CaptionSection(controller: controller),
                            _LocationSection(controller: controller),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _UploadFooter(controller: controller),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {

              Get.delete<CreatePostController>();
              Get.back();

            },
            icon: const Icon(
              Icons.chevron_left,
              color: AppColors.createPostRed600,
              size: 24,
            ),
          ),
          const Text(
            'Create Post',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.createPostRed600,
            ),
          ),
          const SizedBox(width: 32), // spacer to balance the back button
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Media carousel with thumbnails, swipe counter, and zoom
// ---------------------------------------------------------------------------
class _MediaCarousel extends StatelessWidget {
  const _MediaCarousel({required this.controller});

  final CreatePostController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main carousel
        SizedBox(
          height: 380,
          child: Obx(() {
            final urls = controller.mediaUrls;
            if (urls.isEmpty) {
              return _EmptyState(onTap: controller.showMediaPicker);
            }
            return PageView.builder(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              itemCount: urls.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key('media_$index'),
                  direction: DismissDirection.up,
                  onDismissed: (_) => controller.removeImageAt(index),
                  background: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 40,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: _MediaPreviewCard(
                    imageUrl: urls[index],
                    currentIndex: index + 1,
                    totalCount: urls.length,
                    onRemove: () {
                      controller.removeImageAt(index);
                    },
                  ),
                );
              },
            );
          }),
        ),
        const SizedBox(height: 12),
        // Swipe counter
        Obx(() {
          final urls = controller.mediaUrls;
          if (urls.isEmpty) return const SizedBox.shrink();
          final current = controller.currentIndex.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${current + 1} of ${urls.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        // Thumbnail strip
        Obx(() {
          final urls = controller.mediaUrls;
          if (urls.isEmpty) return const SizedBox.shrink();
          final current = controller.currentIndex.value;
          return SizedBox(
            height: 76,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: urls.length + 1,
              itemBuilder: (context, index) {
                if (index == urls.length) {
                  return GestureDetector(
                    onTap: controller.showMediaPicker,
                    child: Container(
                      width: 64,
                      height: 64,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.createPostGray300,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.createPostRed600,
                        size: 28,
                      ),
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () => controller.animateToPage(index),
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: index == current
                            ? AppColors.createPostRed600
                            : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: index == current
                          ? [
                              BoxShadow(
                                color: AppColors.createPostRed600.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildMediaImage(urls[index], BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.createPostGray300, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.createPostRed600.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.createPostRed600,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tap to Add Photos & Videos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.createPostGray800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap to choose from gallery',
                style: TextStyle(fontSize: 14, color: AppColors.gray500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Media preview card with zoom and floating shadow
// ---------------------------------------------------------------------------
class _MediaPreviewCard extends StatelessWidget {
  const _MediaPreviewCard({
    required this.imageUrl,
    required this.currentIndex,
    required this.totalCount,
    required this.onRemove,
  });

  final String imageUrl;
  final int currentIndex;
  final int totalCount;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Zoomable image
            InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: _buildMediaImage(imageUrl, BoxFit.cover),
            ),
            // Media type indicator (top-left)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.image, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$currentIndex/$totalCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Delete button (top-right) - Instagram style
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: onRemove,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.black45,
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info banner
// ---------------------------------------------------------------------------
class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.createPostRed600, size: 16),
          SizedBox(width: 8),
          Text(
            'You can add up to 10 photos or videos',
            style: TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Caption section
// ---------------------------------------------------------------------------
class _CaptionSection extends StatelessWidget {
  const _CaptionSection({required this.controller});

  final CreatePostController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit, color: AppColors.createPostRed600, size: 16),
              SizedBox(width: 8),
              Text(
                'Add Caption',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.createPostRed600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                TextField(
                  controller: controller.captionController,
                  maxLength: controller.captionMaxLength,
                  maxLines: null,
                  minLines: 5,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.createPostGray800,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Write something about your post...',
                    hintStyle: TextStyle(color: AppColors.gray400),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(16, 16, 16, 32),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 16,
                  child: Obx(
                    () => Text(
                      '${controller.caption.value.length}/${controller.captionMaxLength}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Location section
// ---------------------------------------------------------------------------
class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.controller});

  final CreatePostController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: controller.addLocation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColors.createPostRed600,
                          size: 16,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Add Location',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.createPostRed600,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.gray400,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky footer with the "Upload Post" button
// ---------------------------------------------------------------------------
class _UploadFooter extends StatelessWidget {
  const _UploadFooter({required this.controller});

  final CreatePostController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray100, width: 1)),
      ),
      child: Obx(
        () => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.mediaUrls.isEmpty
                ? null
                : controller.uploadPost,
            style:
                ElevatedButton.styleFrom(
                  backgroundColor: AppColors.createPostRed700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ).copyWith(
                  overlayColor: WidgetStateProperty.all(
                    AppColors.createPostRed800,
                  ),
                ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload, size: 22),
                SizedBox(width: 8),
                Text(
                  'Upload Post',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
