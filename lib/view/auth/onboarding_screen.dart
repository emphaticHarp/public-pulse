import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/core/theme/app_font.dart';
import 'login_page.dart';

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

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
  }

  void _onBack() {
    if (_currentIndex == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onNext() {
    if (_currentIndex == _slides.length - 1) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
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

  Widget _buildLogo() {
    return Image.asset(
      kLogoAssetPath,
      height: 56,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox(height: 56),
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
                  GestureDetector(
                    onTap: _onSkip,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Text(
                        'Skip',
                        style: AppTextStyles.skipText.copyWith(
                          color: AppColors.grayText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) => _buildSlide(_slides[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _currentIndex;
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _currentIndex == 0 ? 0.0 : 1.0,
                    child: IgnorePointer(
                      ignoring: _currentIndex == 0,
                      child: GestureDetector(
                        onTap: _onBack,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.buttonBackground,
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.darkText,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: GestureDetector(
                        onTap: _onNext,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.accentRed,
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentRed.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentIndex == _slides.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                                style: AppTextStyles.nextButtonText.copyWith(
                                  color: AppColors.primaryWhite,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.primaryWhite,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
