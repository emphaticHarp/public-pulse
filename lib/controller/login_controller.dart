import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/services/auth_service.dart';
import 'package:public_pulse/widget/login/login_code_page.dart';
// import 'package:public_pulse/view/main/main_page.dart';

class LoginController extends GetxController {
  final RxBool isGoogleLoading = false.obs;
  final RxBool _isCheckingUser = false.obs;
  final RxBool isLoading = false.obs;

  final AuthService _authService = Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();

    debugPrint("LoginController.onInit: initializing");

    _authService.listenToAuthChanges(
      onSignedIn: (user) async {
        debugPrint(
          "LoginController.onSignedIn: callback fired for user=${user.id}",
        );

        if (_isCheckingUser.value) return;

        _isCheckingUser.value = true;

        try {
          debugPrint("User signed in successfully.");

          Get.offAll(() => LoginCodePage());
        } finally {
          _isCheckingUser.value = false;
        }
      },
    );

    debugPrint("LoginController.onInit: auth listener registered");
  }

  Future<void> signInWithGoogle() async {
    debugPrint("signInWithGoogle: button pressed, starting flow");
    try {
      isGoogleLoading.value = true;
      debugPrint("signInWithGoogle: isGoogleLoading set to true");

      final success = await _authService.signInWithGoogle();
      debugPrint("signInWithGoogle: result success = $success");

      if (!success) {
        debugPrint(
          "signInWithGoogle: sign-in cancelled or failed, showing snackbar",
        );
        Get.snackbar("Login Failed", "Google Sign-In was cancelled or failed.");
      }
    } catch (e, stackTrace) {
      debugPrint("signInWithGoogle ERROR: $e");
      debugPrint("signInWithGoogle: stackTrace = $stackTrace");
      Get.snackbar("Login Failed", e.toString());
    } finally {
      isGoogleLoading.value = false;
      debugPrint("signInWithGoogle: isGoogleLoading set to false");
    }
  }

  @override
  void onClose() {
    debugPrint("LoginController.onClose: controller closing");
    super.onClose();
  }

  Future<void> signInWithApple() async {
    debugPrint("signInWithApple: button pressed, starting flow");
    try {
      isLoading.value = true;
      debugPrint("signInWithApple: isLoading set to true");
      Get.snackbar("Coming Soon", "Apple Sign-In will be available soon.");
      debugPrint("signInWithApple: 'Coming Soon' snackbar shown");
    } catch (e, stackTrace) {
      debugPrint("signInWithApple ERROR: $e");
      debugPrint("signInWithApple: stackTrace = $stackTrace");
      Get.snackbar("Login Failed", "Unable to sign in.");
    } finally {
      isLoading.value = false;
      debugPrint("signInWithApple: isLoading set to false");
    }
  }
}
