import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/core/theme/app_font.dart';
import 'package:public_pulse/controller/login_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final controller = Get.find<LoginController>();

  static const String kBackgroundImagePath = 'assets/images/login_bg.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginSurface,
      body: Column(
        children: [
          Transform.translate(
            offset: const Offset(0, -10),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.47,
              width: double.infinity,
              child: Image.asset(kBackgroundImagePath, fit: BoxFit.cover),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: _buildLoginSection(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /////login box
  Widget _buildLoginSection(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.loginBoxShadow,
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back!',
            style: AppTextStyles.loginHeading.copyWith(
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Login to continue to Public Pulse',
            style: AppTextStyles.subtitle.copyWith(color: AppColors.slate400),
          ),
          const SizedBox(height: 32),

          // Google Sign-In Button
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: controller.isGoogleLoading.value
                    ? null
                    : controller.signInWithGoogle,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: const BorderSide(color: AppColors.gray200),
                ),
                child: controller.isGoogleLoading.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/images/google.webp",
                            width: 22,
                            height: 22,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Continue with Google",
                            style: AppTextStyles.buttonText,
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Apple Sign-In Button
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.signInWithApple,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pureBlack,
                  foregroundColor: AppColors.primaryWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryWhite,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apple, size: 24),
                          SizedBox(width: 12),
                          Text(
                            "Continue with Apple",
                            style: AppTextStyles.buttonText,
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              "By continuing, you agree to our\nTerms & Privacy Policy",
              textAlign: TextAlign.center,
              style: AppTextStyles.footerText.copyWith(
                color: AppColors.slate400,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
