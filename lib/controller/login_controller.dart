import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/services/auth_service.dart';
import 'package:public_pulse/widget/local/app_alerts.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/view/login/login_code_page.dart';
import 'package:public_pulse/view/main/main_page.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/core/services/initial_permission_service.dart';
import 'package:public_pulse/controller/profile_controller.dart';
import 'package:public_pulse/core/cache/cache_manager.dart';

class LoginController extends GetxController {
  final RxBool isGoogleLoading = false.obs;
  final RxBool _isCheckingUser = false.obs;
  final RxBool isLoading = false.obs;

  final AuthService _authService = Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();

    _authService.listenToAuthChanges(
      onSignedIn: (user) async {
        
        if (_isCheckingUser.value) return;

        _isCheckingUser.value = true;

        try {
          final profile = await _authService.getCurrentProfile();

          if (profile == null) {
            CustomAlert.error(
              title: 'Error',
              message: 'Unable to load your profile.',
            );
            return;
          }

          final status = (profile['status'] ?? 'pending')
              .toString()
              .toLowerCase();

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
              CustomAlert.error(
                title: 'Account Blocked',
                message: 'Please contact the administrator.',
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

  }

  Future<void> signInWithGoogle() async {

    try {
      isGoogleLoading.value = true;

      // ============================================================
      // CLEAR OLD PROFILE CACHE BEFORE A FRESH LOGIN
      // ============================================================

      if (Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().invalidateProfile();
      } else {
        await CacheManager.clearUserProfileCache();
      }

      // ============================================================
      // GOOGLE LOGIN
      // ============================================================

      final success = await _authService.signInWithGoogle();

      if (!success) {
        CustomAlert.error(
          title: 'Login Failed',
          message: 'Google Sign-In was cancelled or failed.',
        );
      }

      // Do NOT navigate here.
      // onSignedIn() will handle navigation.
    } catch (e) {
      CustomAlert.error(
        title: 'Login Failed',
        message: e.toString(),
      );
    } finally {
      isGoogleLoading.value = false;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> signInWithApple() async {
    try {
      isLoading.value = true;
      CustomAlert.show(
        title: 'Coming Soon',
        message: 'Apple Sign-In will be available soon.',
        icon: Icons.info_outline_rounded,
        color: AppColors.loginAccentRed,
      );
    } catch (e, stackTrace) {
      CustomAlert.error(
        title: 'Login Failed',
        message: 'Unable to sign in.',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
