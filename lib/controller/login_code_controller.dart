import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/services/auth_service.dart';
import 'package:public_pulse/view/main/main_page.dart';

class LoginCodeController extends GetxController {
  final pinController = TextEditingController();

  final isLoading = false.obs;

  final AuthService _authService = Get.find<AuthService>();

  Future<void> verifyCode() async {
    try {
      isLoading.value = true;

      final code = pinController.text.trim().toUpperCase();

      if (code.length != 6) {
        Get.snackbar("Invalid Code", "Enter a 6-character code.");
        return;
      }

      final valid = await _authService.verifyLoginCode(code);

      if (!valid) {
        Get.snackbar("Invalid Code", "Incorrect login code.");
        return;
      }

     await _authService.activateCurrentUser(code);

      Get.offAll(() => MainPage());
    } catch (e) {
      Get.snackbar("Error", "Something went wrong.");
    } finally {
      isLoading.value = false;
    }
  }
}
