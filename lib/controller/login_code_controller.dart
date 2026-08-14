import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/services/auth_service.dart';
import 'package:public_pulse/view/main/main_page.dart';
import 'package:public_pulse/widget/local/app_alert.dart';

class LoginCodeController extends GetxController {
  final pinController = TextEditingController();

  final isLoading = false.obs;

  final AuthService _authService = Get.find<AuthService>();

  Future<void> verifyCode() async {
    try {
      isLoading.value = true;

      final code = pinController.text.trim().toUpperCase();

      if (code.length != 6) {
        CustomAlert.show(
          title: 'Invalid Code',
          message: 'Enter a 6-character code.',
          icon: Icons.warning_amber_rounded,
          color: AppColors.semanticOrange,
        );
        return;
      }

      final valid = await _authService.verifyLoginCode(code);

      if (!valid) {
        CustomAlert.show(
          title: 'Invalid Code',
          message: 'Incorrect login code.',
          icon: Icons.warning_amber_rounded,
          color: AppColors.semanticOrange,
        );
        return;
      }

     await _authService.activateCurrentUser(code);

      Get.offAll(() => MainPage());
    } catch (e) {
      CustomAlert.show(
        title: 'Error',
        message: 'Something went wrong.',
        icon: Icons.error_outline,
        color: AppColors.semanticRed,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
