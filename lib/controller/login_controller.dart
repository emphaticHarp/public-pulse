import 'package:get/get.dart';
import 'package:public_pulse/core/services/auth_service.dart';
import 'package:public_pulse/view/main/main_page.dart';

class LoginController extends GetxController {
  final RxBool isGoogleLoading = false.obs;
  final RxBool _isCheckingUser = false.obs;
  final RxBool isLoading = false.obs;

  final AuthService _authService = AuthService();

  @override
  void onInit() {
    super.onInit();

    _authService.listenToAuthChanges(
      onSignedIn: (user) async {
        if (_isCheckingUser.value) return;

        _isCheckingUser.value = true;

        try {
          final approved = await _authService.userExists();

          if (!approved) {
            await _authService.signOut();

            Get.defaultDialog(
              title: "Access Denied",
              middleText:
                  "Your account is not approved yet.\n\nPlease contact the administrator.",
            );

            return;
          }

          Get.offAll(() => MainPage());
        } finally {
          _isCheckingUser.value = false;
        }
      },
    );
  }

  Future<void> signInWithGoogle() async {
    try {
      isGoogleLoading.value = true;

      await _authService.signInWithGoogle();
    } catch (e) {
      Get.snackbar("Login Failed", "Unable to sign in. Please try again.");
    } finally {
      isGoogleLoading.value = false;
    }
  }

  @override
  void onClose() {
    _authService.dispose();
    super.onClose();
  }

  Future<void> signInWithApple() async {
    try {
      isLoading.value = true;

      // TODO:
      // Implement Apple Sign-In with Supabase

      Get.snackbar("Coming Soon", "Apple Sign-In will be available soon.");
    } catch (e) {
      Get.snackbar("Login Failed", "Unable to sign in.");
    } finally {
      isLoading.value = false;
    }
  }
}
