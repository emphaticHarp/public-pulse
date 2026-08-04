import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/services/auth_service.dart';
import 'package:public_pulse/widget/login/login_code_page.dart';
import 'package:public_pulse/view/main/main_page.dart';
import 'package:public_pulse/view/auth/login_page.dart';
import 'package:public_pulse/widget/local/app_alert.dart';

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
          final profile = await _authService.getCurrentProfile();

          if (profile == null) {
            debugPrint("LoginController: profile is null, signing out and redirecting to login");
            await _authService.signOut();
            Get.offAll(() => LoginPage());
            return;
          }

          final status = (profile['status'] ?? 'pending')
              .toString()
              .toLowerCase();

          debugPrint("User login status = $status");

          switch (status) {
            case "active":
              Get.offAll(() => MainPage());
              break;

            case "pending":
              Get.offAll(() => LoginCodePage());
              break;

            case "blocked":
              CustomAlert.show(
                title: 'Account Blocked',
                message: 'Please contact the administrator.',
                icon: Icons.block,
                color: Colors.red,
              );

              await _authService.signOut();

              Get.offAllNamed("/login"); // or Get.offAll(() => LoginPage());

              break;

            default:
              Get.offAll(() => LoginCodePage());
          }
        } finally {
          _isCheckingUser.value = false;
        }
      },
    );

    debugPrint("LoginController.onInit: auth listener registered");
  }

  Future<void> signInWithGoogle() async {
    debugPrint("signInWithGoogle: button pressed");

    try {
      isGoogleLoading.value = true;

      final success = await _authService.signInWithGoogle();

      if (!success) {
        CustomAlert.show(
          title: 'Login Failed',
          message: 'Google Sign-In was cancelled or failed.',
          icon: Icons.error_outline,
          color: Colors.red,
        );
      }

      // Do NOT navigate here.
      // onSignedIn() will handle navigation.
    } catch (e) {
      CustomAlert.show(
        title: 'Login Failed',
        message: e.toString(),
        icon: Icons.error_outline,
        color: Colors.red,
      );
    } finally {
      isGoogleLoading.value = false;
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
      CustomAlert.show(
        title: 'Coming Soon',
        message: 'Apple Sign-In will be available soon.',
        icon: Icons.info_outline,
        color: Colors.blue,
      );
      debugPrint("signInWithApple: 'Coming Soon' snackbar shown");
    } catch (e, stackTrace) {
      debugPrint("signInWithApple ERROR: $e");
      debugPrint("signInWithApple: stackTrace = $stackTrace");
      CustomAlert.show(
        title: 'Login Failed',
        message: 'Unable to sign in.',
        icon: Icons.error_outline,
        color: Colors.red,
      );
    } finally {
      isLoading.value = false;
      debugPrint("signInWithApple: isLoading set to false");
    }
  }
}
