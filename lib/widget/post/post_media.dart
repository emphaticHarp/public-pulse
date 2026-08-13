import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/core/cache/image_cache_key.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostMedia extends StatelessWidget {
  final String imageUrl;
  const PostMedia({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            cacheKey: supabaseStorageCacheKey(imageUrl),
            fit: BoxFit.cover,

            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,

            placeholder: (context, url) => Container(color: AppColors.gray100),

            errorWidget: (context, url, error) => Container(
              color: AppColors.gray100,
              child: const Icon(
                Icons.broken_image,
                color: AppColors.gray400,
                size: 48,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PostCarouselMedia extends StatelessWidget {
  final List<String> imageUrls;
  final String postId;

  const PostCarouselMedia({
    super.key,
    required this.imageUrls,
    required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      final currentIndex = controller.carouselIndexes[postId] ?? 0;

      return AspectRatio(
        aspectRatio: 4 / 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: imageUrls.length,
              controller: controller.getCarouselPageController(
                postId,
                currentIndex,
              ),
              onPageChanged: (value) {
                controller.carouselIndexes[postId] = value;
                controller.carouselScrollFractions[postId] = 0.0;
              },
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: imageUrls[index],
                  cacheKey: supabaseStorageCacheKey(imageUrls[index]),
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (context, url) {
                    return Container(color: AppColors.gray100);
                  },
                  errorWidget: (context, url, error) {
                    return Container(
                      color: AppColors.gray100,
                      child: const Icon(
                        Icons.broken_image,
                        color: AppColors.gray400,
                        size: 48,
                      ),
                    );
                  },
                );
              },
            ),

            // --------------------------------------------------
            // IMAGE COUNTER
            // --------------------------------------------------
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${currentIndex + 1}/${imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // DOTS
            // --------------------------------------------------
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: _SmoothDots(
                count: imageUrls.length,
                currentIndex: currentIndex,
                scrollFraction:
                    controller.carouselScrollFractions[postId] ?? 0.0,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SmoothDots extends StatelessWidget {
  final int count;
  final int currentIndex;
  final double scrollFraction;

  const _SmoothDots({
    required this.count,
    required this.currentIndex,
    required this.scrollFraction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final distance = (index - currentIndex - scrollFraction).abs().clamp(
          0.0,
          1.0,
        );

        final width = 7.0 + (13.0 * (1.0 - distance));

        final opacity = 0.5 + (0.5 * (1.0 - distance));

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: width,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.white.withValues(alpha: opacity),
          ),
        );
      }),
    );
  }
}
