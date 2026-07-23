import 'package:get/get.dart';
import 'package:public_pulse/view/main/main_page.dart';

class LoginController extends GetxController {

  final RxBool isLoading = false.obs;

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;

      // TODO:
      // Google Sign-In
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