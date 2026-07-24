import 'package:get/get.dart';
import 'package:public_pulse/view/auth/onboarding_screen.dart';

class VersionCheckController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    startup();
  }

  Future<void> startup() async {
    await Future.delayed(const Duration(seconds: 3));

    Get.offAll(() => OnboardingScreen());
  }
}