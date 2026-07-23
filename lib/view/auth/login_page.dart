import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/core/theme/app_font.dart';
import 'package:public_pulse/widget/local/app_input_box.dart';
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
            color: Colors.black.withValues(alpha: 0.08),
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
          AppInputBox(
            controller: controller.identifierController,
            hintText: 'Email or Phone Number',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 20),
          Obx(
            () => AppInputBox(
              controller: controller.passwordController,
              hintText: 'Password',
              prefixIcon: Icons.lock_outline,
              obscureText: controller.obscurePassword.value,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscurePassword.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.slate400,
                  size: 20,
                ),
                onPressed: controller.togglePassword,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: AppTextStyles.linkText.copyWith(
                  color: AppColors.loginAccentRed,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.loginAccentRed,
                foregroundColor: AppColors.primaryWhite,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
                shadowColor: AppColors.loginAccentRed.withValues(alpha: 0.3),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Login', style: AppTextStyles.buttonText),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(
                child: Divider(color: AppColors.slate200, height: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR CONTINUE WITH',
                  style: AppTextStyles.dividerLabel.copyWith(
                    color: AppColors.slate400,
                  ),
                ),
              ),
              const Expanded(
                child: Divider(color: AppColors.slate200, height: 1),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: AppTextStyles.footerText,
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Sign Up',
                    style: AppTextStyles.signUpLink.copyWith(
                      color: AppColors.loginAccentRed,
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
