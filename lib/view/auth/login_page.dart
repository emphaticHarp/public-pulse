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
        
         
         
         
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              
          ),
          )
         
        ],
      ),
    );
  }
}
