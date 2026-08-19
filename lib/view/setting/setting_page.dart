import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/setting_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_font.dart';
import '../../widget/setting/setting_widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  static const double _contentMaxWidth = 600;

  @override
  Widget build(BuildContext context) {
    // Ensuring the controller is registered. Assuming it is injected elsewhere.
    final controller = Get.find<SettingController>();

    final screenWidth = MediaQuery.sizeOf(context).width;

    final horizontalPadding = screenWidth < 360
        ? 12.0
        : screenWidth < 600
        ? 20.0
        : 24.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryText,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Settings',
          style: AppTextStyles.settingsHeading.copyWith(
            color: AppColors.primaryText,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ACCOUNT SECTION
                  const SettingSectionHeader(title: 'Account'),
                  SettingCardGroup(
                    children: [
                      Obx(
                        () => SettingStatusItem(
                          icon: Icons.shield_outlined,
                          title: 'Account Status',
                          subtitle: 'Current status of your account',
                          statusText: controller.accountStatusText,
                          statusColor: controller.accountStatusColor,
                          showDivider: true,
                        ),
                      ),
                      Obx(
                        () => _ReferralCodeCard(
                          code: controller.referralCode,
                          onCopy: () {
                            if (controller.referralCode.isNotEmpty) {
                              controller.copyReferralCode(
                                controller.referralCode,
                              );
                            }
                          },
                        ),
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
                        icon: Icons.description_outlined,
                        title: 'Terms & Conditions',
                        subtitle: 'Read our terms of service',
                        onTap: controller.openTermsAndConditions,
                        showDivider: true,
                      ),

                      SettingNavItem(
                        icon: Icons.person_remove_outlined,
                        title: 'Account Deletion Policy',
                        subtitle: 'Learn about account deletion',
                        onTap: controller.openAccountDeletionPolicy,
                        showDivider: false,
                      ),
                    ],
                  ),

                  // ACCOUNT ACTIONS SECTION
                  const SettingSectionHeader(title: 'Account Actions'),
                  SettingCardGroup(
                    children: [
                      SettingNavItem(
                        icon: Icons.delete_outline_rounded,
                        title: 'Delete Account',
                        subtitle: 'Permanently delete your account',
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
                                    color: AppColors.loginAccentRed,
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

                  // APP VERSION + COMPANY
                  const SizedBox(height: 24),

                  Center(
                    child: FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final version = snapshot.data?.version ?? '';

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              version.isNotEmpty
                                  ? 'Version $version'
                                  : 'Version',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              'Insyssky Softtech Pvt Ltd',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.section),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferralCodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;

  const _ReferralCodeCard({required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final bool hasCode = code.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.loginAccentRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.loginAccentRed.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // TITLE
          // =====================================================

          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.loginAccentRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.loginAccentRed,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Referral Code',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Share this code to invite someone to Public Pulse',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // =====================================================
          // CODE
          // =====================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasCode ? code : 'Not available',
                    style: TextStyle(
                      fontSize: hasCode ? 20 : 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: hasCode ? 2.5 : 0,
                      color: hasCode
                          ? AppColors.loginAccentRed
                          : AppColors.textSecondary,
                    ),
                  ),
                ),

                if (hasCode)
                  GestureDetector(
                    onTap: onCopy,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.loginAccentRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: AppColors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Copy',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (hasCode) ...[
            const SizedBox(height: 10),

            const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'New users can use this code during login.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
