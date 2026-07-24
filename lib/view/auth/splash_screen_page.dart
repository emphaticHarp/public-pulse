import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/controller/version_check.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/core/theme/app_font.dart';

const String _logoAsset = 'assets/images/logo.webp';

class SplashScreenPage extends StatelessWidget {
  SplashScreenPage({super.key});

  final VersionCheckController controller = Get.put(VersionCheckController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: _GlowCircle(
                size: 220,
                color: AppColors.accentRed.withValues(alpha: 0.05),
              ),
            ),

            Positioned(
              bottom: -100,
              left: -70,
              child: _GlowCircle(
                size: 260,
                color: AppColors.accentRed.withValues(alpha: 0.04),
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    _logoAsset,
                    width: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return RichText(
                        text: TextSpan(
                          style: AppTextStyles.splashLogo,
                          children: [
                            TextSpan(
                              text: 'PUBLIC',
                              style: TextStyle(color: AppColors.accentRed),
                            ),
                            TextSpan(
                              text: ' PULSE',
                              style: TextStyle(color: AppColors.darkText),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'YOUR VOICE. YOUR COMMUNITY.',
                    style: AppTextStyles.tagline.copyWith(
                      color: AppColors.grayText,
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 36,
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Text(
                    'SYNCING YOUR FEED',
                    style: AppTextStyles.syncingText.copyWith(
                      color: AppColors.grayText.withValues(alpha: 0.7),
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

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
