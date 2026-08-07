import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:public_pulse/model/app_version_model.dart';
import 'package:public_pulse/core/repository/version_repository.dart';
import 'package:public_pulse/core/services/auth_service.dart';

import 'package:public_pulse/view/auth/login_page.dart';
import 'package:public_pulse/view/auth/onboarding_screen.dart';
import 'package:public_pulse/view/main/main_page.dart';
import 'package:public_pulse/widget/login/login_code_page.dart';
import 'package:public_pulse/core/theme/app_colors.dart';

class VersionCheckController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    startup();
  }

  Future<void> startup() async {
    await Future.delayed(const Duration(seconds: 3));

    final AppVersionModel? update = await checkForUpdate();

    if (update != null) {
      await showUpdateDialog(update);

      if (update.forceUpdate) {
        return;
      }
    }

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

      final status = (profile['status'] ?? 'pending').toString().toLowerCase();

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

  Future<AppVersionModel?> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();

    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

    final latest = await VersionRepository.instance.getLatestVersion();

    if (latest == null) return null;

    // Already on latest
    if (currentBuild >= latest.buildNumber) {
      return null;
    }

    // Force update if below minimum supported
    if (currentBuild < latest.minimumSupportedBuild) {
      return latest;
    }

    // Optional update
    return latest;
  }

  Future<void> showUpdateDialog(AppVersionModel update) async {
    await Get.dialog(
      PopScope(
        canPop: !update.forceUpdate,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.system_update_alt_rounded,
                  size: 70,
                  color: AppColors.loginAccentRed,
                ),

                const SizedBox(height: 20),

                Text(
                  update.updateTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  update.updateMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppColors.black54),
                ),

                const SizedBox(height: 20),

                if (update.releaseNotes != null &&
                    update.releaseNotes!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      update.releaseNotes!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    if (!update.forceUpdate)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          child: const Text("Later"),
                        ),
                      ),

                    if (!update.forceUpdate) const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final uri = Uri.parse(update.downloadUrl);

                          final launched = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );

                          if (!launched) {
                            Get.snackbar(
                              "Update Failed",
                              "Unable to open download link.",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }

                          if (!update.forceUpdate) {
                            Get.back();
                          }
                        },
                        child: const Text("Update Now"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: !update.forceUpdate,
    );
  }
}
