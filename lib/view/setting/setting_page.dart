import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/setting_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_font.dart';
import '../../widget/setting/setting_widgets.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensuring the controller is registered. Assuming it is injected elsewhere.
    final controller = Get.put(SettingController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primaryText, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text('Settings', style: AppTextStyles.settingsHeading.copyWith(color: AppColors.primaryText)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ACCOUNT SECTION
            const SettingSectionHeader(title: 'Account'),
            SettingCardGroup(
              children: [
                SettingStatusItem(
                  icon: Icons.shield_outlined,
                  title: 'Account Status',
                  subtitle: 'Your account is active',
                  statusText: 'Active',
                  statusColor: AppColors.success,
                  showDivider: true,
                ),
                SettingCopyItem(
                  icon: Icons.card_giftcard_rounded,       ///changes
                  title: 'Referral Code',
                  subtitle: 'Share code ',
                  valueText: 'PP-8C11E0',
                  onCopy: () => controller.copyReferralCode('PP-8C11E0'),
                  showDivider: false,
                ),
              ],
            ),

            // GENERAL SECTION
            const SettingSectionHeader(title: 'General'),
            SettingCardGroup(
              children: [
                Obx(
                  () => SettingToggleItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Push Notifications',
                    subtitle: 'Stay updated with alerts',
                    value: controller.isPushNotificationEnabled.value,
                    onChanged: controller.togglePushNotifications,
                    showDivider: true,
                  ),
                ),
                SettingNavItem(
                  icon: Icons.light_mode_outlined,
                  title: 'Theme',
                  subtitle: 'Choose your preferred theme',
                  valueText: controller.currentThemeMode == ThemeMode.dark
                      ? 'Dark'
                      : 'Light',
                  onTap: () {
                    controller.showThemeDialog();
                  },
                  showDivider: false,
                ),
              ],
            ),

            // INFORMATION SECTION
            const SettingSectionHeader(title: 'Information'),
            SettingCardGroup(
              children: [
                SettingNavItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'How we protect your data',
                  onTap: controller.openPrivacyPolicy,
                  showDivider: true,
                ),
                SettingNavItem(
                  icon: Icons.headset_mic_outlined,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  onTap: controller.openHelpSupport,
                  showDivider: true,
                ),
                SettingNavItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About Us',
                  subtitle: 'Learn more about our app',
                  onTap: controller.openAboutUs,
                  showDivider: false,
                ),
              ],
            ),

            // ACCOUNT ACTIONS SECTION
            const SettingSectionHeader(title: 'Account Actions'),
            SettingCardGroup(
              children: [
                SettingNavItem(
                  icon: Icons.power_settings_new_rounded,
                  title: 'Deactivate Account',
                  subtitle: 'Temporarily deactivate your account',
                  onTap: () => controller.deactivateAccount(context),
                  isDestructive: true,
                  showDivider: true,
                ),
                SettingNavItem(
                  icon: Icons.person_off_outlined,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account and data',
                  onTap: () => controller.deleteAccount(context),
                  isDestructive: true,
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SettingCardGroup(
              children: [
                Obx(
                  () => controller.isLoggingOut.value
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.danger,
                            ),
                          ),
                        )
                      : SettingNavItem(
                          icon: Icons.logout_rounded,
                          title: 'Logout',
                          subtitle: 'Sign out from this device',
                          onTap: controller.logout,
                          isDestructive: true,
                          showDivider: false,
                        ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.section),
          ],
        ),
      ),
    );
  }
}
