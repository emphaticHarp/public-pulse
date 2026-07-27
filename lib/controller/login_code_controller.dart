import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginCodeController extends GetxController {
  final TextEditingController pinController = TextEditingController();

  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    pinController.dispose();
    super.onClose();
  }

  Future<void> verifyCode() async {
    final code = pinController.text.trim();

    if (code.length != 6) {
      Get.snackbar(
        "Invalid Code",
        "Please enter a 6-digit code.",
      );
      return;
    }

    isLoading.value = true;

    try {
      // Verification will be added later.
    } finally {
      isLoading.value = false;
    }
  }
}