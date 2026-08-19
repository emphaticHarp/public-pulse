import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/core/services/auth_service.dart';
import 'package:public_pulse/core/cache/hive_boxes.dart';
import 'package:public_pulse/core/cache/cache_manager.dart';
import 'package:public_pulse/controller/profile_controller.dart';
import 'package:public_pulse/view/auth/login_page.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/controller/notification_controller.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/core/services/current_user_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:public_pulse/view/setting/legal_webview_page.dart';
import 'package:public_pulse/widget/local/app_alerts.dart';

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

  // for displaying account status and referral code in the settings page

  /// Reactive account status — synced from ProfileController.
  final _accountStatus = 'unknown'.obs;

  /// Reactive referral code — synced from ProfileController.
  final _referralCode = ''.obs;

  /// Finds the current user's ProfileController (tagged 'my_profile' or untagged).
  ProfileController? get _profileController {
    if (Get.isRegistered<ProfileController>(tag: 'my_profile')) {
      return Get.find<ProfileController>(tag: 'my_profile');
    }

    if (Get.isRegistered<ProfileController>()) {
      return Get.find<ProfileController>();
    }

    return null;
  }

  String get accountStatus => _accountStatus.value;

  String get referralCode => _referralCode.value;

  /// Syncs account status and referral code from the ProfileController.
  /// Called on init and whenever the profile changes.
  void _syncProfileData() {
    final pc = _profileController;
    final profile = pc?.profile.value;

    _accountStatus.value = profile?.accountStatus ?? 'unknown';
    _referralCode.value = profile?.referCode ?? '';
  }

  String get accountStatusText {
    switch (accountStatus.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'suspended':
        return 'Suspended';
      case 'banned':
        return 'Banned';
      case 'deleted':
        return 'Deleted';
      default:
        return 'Unknown';
    }
  }

  Color get accountStatusColor {
    switch (accountStatus.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'suspended':
      case 'inactive':
        return AppColors.semanticOrange;
      case 'banned':
      case 'deleted':
        return AppColors.loginAccentRed;
      default:
        return AppColors.primaryText;
    }
  }

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

    // Sync profile data immediately (in case profile is already loaded).
    _syncProfileData();

    // Listen to profile changes in the ProfileController.
    // Use a small delay to allow lazy-loaded ProfileController to initialise.
    _observeProfileChanges();
  }

  /// Sets up a listener on the ProfileController's profile observable.
  /// When the profile loads or updates, account status & referral code refresh.
  Worker? _profileWorker;

  void _observeProfileChanges() {
    // Clean up any previous worker.
    _profileWorker?.dispose();

    // Try to attach immediately.
    final pc = _profileController;
    if (pc != null) {
      _profileWorker = ever(pc.profile, (_) {
        _syncProfileData();
      });
      return;
    }

    // ProfileController not registered yet — retry after a short delay.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (Get.isRegistered<SettingController>() && _profileWorker == null) {
        final delayedPc = _profileController;
        if (delayedPc != null) {
          _profileWorker = ever(delayedPc.profile, (_) {
            _syncProfileData();
          });
          _syncProfileData(); // Pull current value now that it exists.
        } else {}
      }
    });
  }

  @override
  void onClose() {
    _profileWorker?.dispose();
    super.onClose();
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
  }

  // ── Referral Code ─────────────────────────────────────────────────────────

  /// Copies [code] to the system clipboard and shows a snackbar.
  void copyReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));

    CustomAlert.show(
      title: 'Referral Code Copied',
      message: '$code copied to clipboard',
      icon: Icons.copy_rounded,
      color: AppColors.success,
      duration: const Duration(seconds: 2),
    );
  }

  // section for showing the web view dialog for legal documents like privacy policy, terms and conditions, and account deletion policy

  // ── Information Placeholders ───────────────────────────────────────────────
  void openPrivacyPolicy() {
    Get.to(
      () => LegalWebViewPage(
        title: 'Privacy Policy',
        url: dotenv.env['PRIVACY_POLICY_URL'] ?? '',
      ),
    );
  }

  void openTermsAndConditions() {
    Get.to(
      () => LegalWebViewPage(
        title: 'Terms & Conditions',
        url: dotenv.env['TERMS_AND_CONDITIONS_URL'] ?? '',
      ),
    );
  }

  void openAccountDeletionPolicy() {
    Get.to(
      () => LegalWebViewPage(
        title: 'Account Deletion Policy',
        url: dotenv.env['ACCOUNT_DELETION_POLICY_URL'] ?? '',
      ),
    );
  }

  // ── Account Actions ────────────────────────────────────────────────────────

  /// Shows a confirmation dialog then permanently deletes the account.
  Future<void> deleteAccount(BuildContext context) async {
    if (isAccountActionLoading.value) return;

    // ============================================================
    // STEP 1 - NORMAL CONFIRMATION
    // ============================================================

    final firstConfirmed = await _showDestructiveDialog(
      context,
      title: 'Delete Account?',
      message:
          'Your account and data will be permanently deleted. '
          'This action cannot be undone.',
      actionLabel: 'Continue',
    );

    if (!firstConfirmed) return;

    // ============================================================
    // STEP 2 - TYPE DELETE
    // ============================================================

    final deleteConfirmed = await _showDeleteTypingDialog(context);

    if (!deleteConfirmed) return;

    // ============================================================
    // DELETE ACCOUNT
    // ============================================================

    isAccountActionLoading.value = true;

    try {
      // Your RPC permanently deletes the account.
      await Supabase.instance.client.rpc('deactivate_account');

      // ==========================================================
      // SIGN OUT
      // ==========================================================

      try {
        final authService = Get.find<AuthService>();
        await authService.signOut();
      } catch (e) {}

      // ==========================================================
      // CLEAR CURRENT USER
      // ==========================================================

      CurrentUserService.instance.clear();

      // ==========================================================
      // CLEAR HIVE CACHE
      // ==========================================================

      await CacheManager.clearUserData();

      // ==========================================================
      // RESET PROFILE
      // ==========================================================

      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();

        await profileController.invalidateProfile();
      }

      // ==========================================================
      // RESET HOME
      // ==========================================================

      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();

        homeController.resetForLogout();
      }

      // ==========================================================
      // REMOVE NOTIFICATION CONTROLLER
      // ==========================================================

      if (Get.isRegistered<NotificationController>()) {
        Get.delete<NotificationController>(force: true);
      }

      // ==========================================================
      // GO TO LOGIN
      // ==========================================================

      Get.offAll(() => LoginPage());
    } catch (e, stackTrace) {
      CustomAlert.error(
        title: 'Delete Failed',
        message: 'Unable to delete your account. Please try again.',
      );
    } finally {
      isAccountActionLoading.value = false;
    }
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

    final confirmed = await _showDestructiveDialog(
      Get.context!,
      title: 'Logout',
      message: 'Are you sure you want to logout from this device?',
      actionLabel: 'Logout',
    );

    if (!confirmed) return;

    isLoggingOut.value = true;

    try {
      // ----------------------------------------------------------
      // 1. Sign out from Supabase / Google
      // ----------------------------------------------------------

      final authService = Get.find<AuthService>();

      await authService.signOut();

      CurrentUserService.instance.clear();

      // ----------------------------------------------------------
      // 2. Clear ALL user-specific Hive cache
      // ----------------------------------------------------------

      await CacheManager.clearUserData();

      // ----------------------------------------------------------
      // 3. Reset ProfileController memory
      // ----------------------------------------------------------

      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();

        await profileController.invalidateProfile();
      }

      // ----------------------------------------------------------
      // 4. Remove user-specific controllers
      // ----------------------------------------------------------
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();

        homeController.resetForLogout();
      }

      if (Get.isRegistered<NotificationController>()) {
        Get.delete<NotificationController>(force: true);
      }

      // ----------------------------------------------------------
      // 5. Go to Login and remove all previous routes
      // ----------------------------------------------------------

      Get.offAll(() => LoginPage());
    } catch (e, stackTrace) {
      CustomAlert.error(
        title: 'Logout Failed',
        message: 'Something went wrong. Please try again.',
      );
    } finally {
      isLoggingOut.value = false;
    }
  }

  // ── Private Helpers ────────────────────────────────────────────────────────

  Future<bool> _showDeleteTypingDialog(BuildContext context) async {
    bool canDelete = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              title: const Text('Confirm Account Deletion'),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To permanently delete your account, type DELETE below.',
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Type DELETE',
                      border: OutlineInputBorder(),
                    ),

                    onChanged: (value) {
                      setState(() {
                        canDelete = value.trim() == 'DELETE';
                      });
                    },
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    // Remove keyboard focus before closing dialog.
                    FocusScope.of(ctx).unfocus();

                    Navigator.of(ctx).pop(false);
                  },
                  child: const Text('Cancel'),
                ),

                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.loginAccentRed,
                    foregroundColor: AppColors.white,
                  ),

                  onPressed: canDelete
                      ? () {
                          // Important:
                          // close keyboard/focus before removing dialog.
                          FocusScope.of(ctx).unfocus();

                          Navigator.of(ctx).pop(true);
                        }
                      : null,

                  child: const Text('Delete Account'),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

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
