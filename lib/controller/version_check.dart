import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/view/auth/login_page.dart';
import 'package:public_pulse/view/auth/onboarding_screen.dart';
import 'package:public_pulse/view/main/main_page.dart';

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
      Get.offAll(() => MainPage());
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
