import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/services/auth_service.dart';
import 'package:public_pulse/view/main/main_page.dart';
import 'package:public_pulse/widget/local/app_alert.dart';
import 'package:public_pulse/core/services/permission_service.dart';
import 'package:flutter/services.dart';

class LoginCodeController extends GetxController {
  final pinController = TextEditingController();

  final isLoading = false.obs;

  final RxString codeError = ''.obs;
  final RxInt shakeTrigger = 0.obs;

  final AuthService _authService = Get.find<AuthService>();

  void clearCodeError() {
    if (codeError.value.isNotEmpty) {
      codeError.value = '';
    }
  }

  void showCodeError(String message) {
    codeError.value = message;
    shakeTrigger.value++;
  }

  Future<void> verifyCode() async {
    try {
      isLoading.value = true;

      final code = pinController.text.trim().toUpperCase();

      codeError.value = '';

      if (code.length != 6) {
        showCodeError('Enter the complete 6-character code');
        return;
      }

      final valid = await _authService.verifyLoginCode(code);

      if (!valid) {
        showCodeError('Incorrect code');

        // Slight vibration for incorrect code
        HapticFeedback.mediumImpact();

        return;
      }
      await _authService.activateCurrentUser(code);

      // ============================================================
      // FIRST-TIME APP PERMISSIONS
      // ============================================================

      
      await PermissionService.requestInitialPermissions();

      // ============================================================
      // OPEN MAIN APP
      // ============================================================

      Get.offAll(() => MainPage());
    } catch (e) {
      CustomAlert.show(
        title: 'Error',
        message: 'Something went wrong.',
        icon: Icons.error_outline,
        color: AppColors.loginAccentRed,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
