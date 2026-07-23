import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/view/main/main_page.dart';

class LoginController extends GetxController {

  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool obscurePassword = true.obs;

  void togglePassword() {
    obscurePassword.toggle();
  }

  void login() {
    // Validation
    // API Call
    // Save Token

    Get.off(() => MainPage());
  }

  @override
  void onClose() {
    identifierController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}