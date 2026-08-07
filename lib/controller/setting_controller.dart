import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../core/services/auth_service.dart';
import '../core/cache/hive_boxes.dart';
import '../core/cache/cache_manager.dart';
import '../controller/profile_controller.dart';
import '../view/auth/login_page.dart';

/// All business logic for the Settings Page.
/// UI must never contain raw logic — only call these methods.
class SettingController extends GetxController {
  static SettingController get to => Get.find();

  // ── Observable State ──────────────────────────────────────────────────────

  /// Whether push notifications are enabled.
  final isPushNotificationEnabled = true.obs;

  /// Whether a logout operation is currently in progress.
  final isLoggingOut = false.obs;

  /// Whether a destructive account action is in progress.
  final isAccountActionLoading = false.obs;

  // ── Theme ─────────────────────────────────────────────────────────────────

  /// Returns the current ThemeMode from GetX's stored value.
  ThemeMode get currentThemeMode =>
      Get.isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Applies [mode] via GetX and persists the choice in Hive.
  Future<void> changeTheme(ThemeMode mode) async {
    Get.changeThemeMode(mode);
    try {
      final box = Hive.box(HiveBoxes.cachedProfiles);
      await box.put('theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  /// Loads persisted theme on controller init.
  @override
  void onInit() {
    super.onInit();
    _restoreTheme();
  }

  void _restoreTheme() {
    try {
      final box = Hive.box(HiveBoxes.cachedProfiles);
      final saved = box.get('theme_mode', defaultValue: 'light') as String;
      if (saved == 'dark') {
        Get.changeThemeMode(ThemeMode.dark);
      } else {
        Get.changeThemeMode(ThemeMode.light);
      }
    } catch (_) {}
  }
///setting theme
  void showThemeDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                currentThemeMode == ThemeMode.light
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: currentThemeMode == ThemeMode.light
                    ? Theme.of(Get.context!).colorScheme.primary
                    : null,
              ),
              title: const Text('Light'),
              onTap: () {
                changeTheme(ThemeMode.light);
                Get.back();
              },
            ),
            ListTile(
              leading: Icon(
                currentThemeMode == ThemeMode.dark
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: currentThemeMode == ThemeMode.dark
                    ? Theme.of(Get.context!).colorScheme.primary
                    : null,
              ),
              title: const Text('Dark'),
              onTap: () {
                changeTheme(ThemeMode.dark);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  void togglePushNotifications(bool value) {
    isPushNotificationEnabled.value = value;
    // Integrate with platform notification service when ready.
    debugPrint('[Settings] Push notifications: $value');
  }

  // ── Referral Code ─────────────────────────────────────────────────────────

  /// Copies [code] to the system clipboard and shows a snackbar.
  void copyReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    Get.snackbar(
      'Copied!',
      'Referral code $code copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // ── Information Placeholders ───────────────────────────────────────────────

  void openPrivacyPolicy() {
    // Navigate to Privacy Policy WebView / page.
    debugPrint('[Settings] Privacy Policy tapped');
    Get.snackbar(
      'Coming Soon',
      'Privacy Policy will be available soon.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void openHelpSupport() {
    // Navigate to Help & Support page.
    debugPrint('[Settings] Help & Support tapped');
    Get.snackbar(
      'Coming Soon',
      'Help & Support will be available soon.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void openAboutUs() {
    // Navigate to About Us page.
    debugPrint('[Settings] About Us tapped');
    Get.snackbar(
      'Coming Soon',
      'About Us will be available soon.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // ── Account Actions ────────────────────────────────────────────────────────

  /// Shows a confirmation dialog then deactivates the account (placeholder).
  Future<void> deactivateAccount(BuildContext context) async {
    final confirmed = await _showDestructiveDialog(
      context,
      title: 'Deactivate Account',
      message:
          'Are you sure you want to deactivate your account? You can reactivate it later by logging in.',
      actionLabel: 'Deactivate',
    );
    if (!confirmed) return;
    // Implement deactivation via Supabase when backend is ready.
    debugPrint('[Settings] Deactivate Account confirmed');
    Get.snackbar(
      'Coming Soon',
      'Account deactivation will be available soon.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  /// Shows a confirmation dialog then permanently deletes the account (placeholder).
  Future<void> deleteAccount(BuildContext context) async {
    final confirmed = await _showDestructiveDialog(
      context,
      title: 'Delete Account',
      message:
          'This action is PERMANENT and cannot be undone. All your data will be erased.',
      actionLabel: 'Delete',
    );
    if (!confirmed) return;
    // Implement permanent deletion via Supabase when backend is ready.
    debugPrint('[Settings] Delete Account confirmed');
    Get.snackbar(
      'Coming Soon',
      'Account deletion will be available soon.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  /// Full logout sequence:
  /// 1. Signs out of Supabase & Google
  /// 2. Clears Hive post cache
  /// 3. Clears profile cache box
  /// 4. Invalidates the ProfileController in-memory state
  /// 5. Navigates back to Login Screen
  Future<void> logout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;
    try {
      debugPrint('[Settings] Starting logout sequence...');

      // 1. Sign out from Supabase + Google
      final authService = Get.find<AuthService>();
      await authService.signOut();
      debugPrint('[Settings] Supabase sign-out complete');

      // 2. Clear cached posts
      await CacheManager.clearPostCache();
      debugPrint('[Settings] Post cache cleared');

      // 3. Clear profile cache
      try {
        final profileBox = Hive.box(HiveBoxes.cachedProfiles);
        await profileBox.clear();
        debugPrint('[Settings] Profile cache cleared');
      } catch (e) {
        debugPrint('[Settings] Profile cache clear error: $e');
      }

      // 4. Invalidate ProfileController in-memory state
      if (Get.isRegistered<ProfileController>()) {
        ProfileController.to.invalidateProfile();
        debugPrint('[Settings] ProfileController state invalidated');
      }

      // 5. Navigate to Login
      Get.offAll(() => LoginPage());
      debugPrint('[Settings] Navigated to LoginPage');
    } catch (e) {
      debugPrint('[Settings] Logout error: $e');
      Get.snackbar(
        'Logout Failed',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoggingOut.value = false;
    }
  }

  // ── Private Helpers ────────────────────────────────────────────────────────

  /// Shows a Material 3 confirmation dialog for destructive actions.
  /// Returns `true` when the user confirms, `false` on cancel/dismiss.
  Future<bool> _showDestructiveDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
