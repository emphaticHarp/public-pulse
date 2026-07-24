import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/core/theme/app_font.dart';
import 'package:get/get.dart';
import 'package:public_pulse/controller/onboarding_controller.dart';


const String kLogoAssetPath = 'assets/images/logo.webp';

class _OnboardSlide {
  final String title;
  final String description;
  final String imageAsset;
  final int imageFlex;
  const _OnboardSlide({
    required this.title,
    required this.description,
    required this.imageAsset,
    this.imageFlex = 11,
  });
}

const List<_OnboardSlide> _slides = [
  _OnboardSlide(
    title: 'Share. Connect. Make an Impact.',
    description:
        'Share photos and videos of issues around you. Together, we can create a better community.',
    imageAsset: 'assets/images/slide_1.webp',
  ),
  _OnboardSlide(
    title: 'Report. Track. Get Results',
    description:
        'Report issues, track their progress in real-time and see the change happen.',
    imageAsset: 'assets/images/slide_3.webp',
    imageFlex: 15,
  ),
  _OnboardSlide(
    title: 'Explore What\'s Trending with Pulse',
    description:
        'Follow trending stories, watch short videos, and stay informed in real time.',
    imageAsset: 'assets/images/slide_2.webp',
  ),
];

class OnboardingScreen extends StatelessWidget {
  OnboardingScreen({super.key});

  final OnboardingController controller = Get.put(OnboardingController());

  Widget _buildLogo() {
    return Image.asset(
      kLogoAssetPath,
      height: 56,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox(height: 56),
    );
  }

  Widget _buildTitle(String title) {
    final lastSpace = title.lastIndexOf(' ');
    final hasSplit = lastSpace != -1;
    final leading = hasSplit ? title.substring(0, lastSpace + 1) : '';
    final lastWord = hasSplit ? title.substring(lastSpace + 1) : title;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          style: AppTextStyles.onboardTitle.copyWith(color: AppColors.darkText),
          children: [
            if (leading.isNotEmpty) TextSpan(text: leading),
            TextSpan(
              text: lastWord,
              style: const TextStyle(color: AppColors.accentRed),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }

  Widget _buildSlide(_OnboardSlide slide) {
    return Column(
      children: [
        Expanded(
          flex: slide.imageFlex,
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Image.asset(
              slide.imageAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildTitle(slide.title),
                const SizedBox(height: 10),
                Text(
                  slide.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.onboardDescription.copyWith(
                    color: AppColors.grayText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Flexible(child: _buildLogo()),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                itemCount: _slides.length,
                onPageChanged: controller.onPageChanged,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == controller.currentIndex.value;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: active
                            ? AppColors.accentRed
                            : AppColors.inactiveDot,
                      ),
                    );
                  }),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.getStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRed,
                    foregroundColor: AppColors.primaryWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: Text(
                    "Get Started",
                    style: AppTextStyles.nextButtonText.copyWith(
                      color: AppColors.primaryWhite,
                    ),
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
