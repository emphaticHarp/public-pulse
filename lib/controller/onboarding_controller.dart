import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:public_pulse/view/auth/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();

  final RxInt currentIndex = 0.obs;

  Timer? _timer;

  static const int totalPages = 3;

  @override
  void onInit() {
    super.onInit();
    startAutoSlide();
  }

  void startAutoSlide() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      int next = currentIndex.value + 1;

      if (next >= totalPages) {
        next = 0;
      }

      pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void onPageChanged(int index) {
    currentIndex.value = index;

    // Restart timer after manual swipe
    startAutoSlide();
  }

  Future<void> getStarted() async {
    final prefs = await SharedPreferences.getInstance();

    // Save that onboarding has been completed
    await prefs.setBool('onboarding_completed', true);

    // Navigate to Login
    Get.off(() => LoginPage());
  }

  @override
  void onClose() {
    _timer?.cancel();
    pageController.dispose();
    super.onClose();
  }
}
