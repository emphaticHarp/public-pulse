import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/view/auth/login_page.dart';
import 'package:public_pulse/view/auth/onboarding_screen.dart';
import 'package:public_pulse/view/main/main_page.dart';
import 'package:public_pulse/core/services/auth_service.dart';
import 'package:public_pulse/widget/login/login_code_page.dart';

class VersionCheckController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    startup();
  }

  Future<void> startup() async {
    await Future.delayed(const Duration(seconds: 3));

    final session = Supabase.instance.client.auth.currentSession;

    // User already logged in
    if (session != null) {
      final AuthService authService = Get.find<AuthService>();

      final profile = await authService.getCurrentProfile();

      if (profile == null) {
        await authService.signOut();
        Get.offAll(() => LoginPage());
        return;
      }

      final status = (profile['status'] ?? 'pending')
          .toString()
          .toLowerCase();

      switch (status) {
        case "active":
          Get.offAll(() => MainPage());
          break;

        case "pending":
          Get.offAll(() => LoginCodePage());
          break;

        case "blocked":
          await authService.signOut();
          Get.offAll(() => LoginPage());
          break;

        default:
          await authService.signOut();
          Get.offAll(() => LoginPage());
          break;
      }

      return;
    }

    // User not logged in
    final prefs = await SharedPreferences.getInstance();

    final completed = prefs.getBool("onboarding_completed") ?? false;

    if (completed) {
      Get.offAll(() => LoginPage());
    } else {
      Get.offAll(() => OnboardingScreen());
    }
  }
}
