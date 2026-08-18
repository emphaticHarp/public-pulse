import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/services/auth_service.dart';
import 'package:public_pulse/view/login/login_code_page.dart';
import 'package:public_pulse/view/main/main_page.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/core/services/initial_permission_service.dart';

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
            Get.snackbar("Error", "Unable to load your profile.");
            return;
          }

          final status = (profile['status'] ?? 'pending')
              .toString()
              .toLowerCase();

          debugPrint("User login status = $status");

          switch (status) {
            case "active":
              // ============================================================
              // FIRST-TIME PERMISSIONS FOR NEW USERS ONLY
              // ============================================================

              await InitialPermissionService.requestIfNeeded(user.id);

              // ============================================================
              // INITIALIZE HOME
              // ============================================================

              final homeController = Get.find<HomeController>();

              await homeController.initializeForUser();

              Get.offAll(() => MainPage());

              break;

            case "pending":
              // This account has entered the new-user registration flow.
              // Remember locally that permissions must be requested
              // after the account becomes ACTIVE.

              await InitialPermissionService.markNewUser(user.id);

              Get.offAll(() => LoginCodePage());

              break;

            case "blocked":
              Get.snackbar(
                "Account Blocked",
                "Please contact the administrator.",
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
        Get.snackbar("Login Failed", "Google Sign-In was cancelled or failed.");
      }

      // Do NOT navigate here.
      // onSignedIn() will handle navigation.
    } catch (e) {
      Get.snackbar("Login Failed", e.toString());
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
