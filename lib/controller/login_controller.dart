import 'package:get/get.dart';
import 'package:public_pulse/view/main/main_page.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:public_pulse/core/services/auth_service.dart';

class LoginController extends GetxController {

  final RxBool isLoading = false.obs;

  final AuthService _authService = AuthService();

final RxBool isGoogleLoading = false.obs;

 Future<void> signInWithGoogle() async {
  try {
    isGoogleLoading.value = true;

    final UserCredential? credential =
        await _authService.signInWithGoogle();

    if (credential == null) {
      return;
    }

    Get.off(() => MainPage());

  } catch (e) {
    Get.snackbar(
      "Login Failed",
      e.toString(),
    );
  } finally {
    isGoogleLoading.value = false;
  }
}

  Future<void> signInWithApple() async {
    try {
      isLoading.value = true;

      // TODO:
      // Apple Sign-In
      // Firebase Authentication
      // Save user
      // Navigate

      Get.off(() => MainPage());

    } catch (e) {
      Get.snackbar(
        "Login Failed",
        e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }
}