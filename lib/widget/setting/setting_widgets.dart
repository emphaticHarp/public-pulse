import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_font.dart';

/// A simple section header text widget.
class SettingSectionHeader extends StatelessWidget {
  final String title;

  const SettingSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        bottom: AppSpacing.sm,
        top: AppSpacing.xl,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.settingsSectionTitle.copyWith(color: AppColors.secondaryText),
      ),
    );
  }
}

/// A card that wraps multiple settings items with a unified background.
class SettingCardGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingCardGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// Base generic settings item with an icon, title, subtitle, and an optional trailing widget.
class SettingItemBase extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool showDivider;

  const SettingItemBase({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDestructive ? AppColors.danger : AppColors.primaryText;
    final iconColor = isDestructive ? AppColors.danger : AppColors.iconColor;
    final iconBgColor = isDestructive
        ? AppColors.danger.withValues(alpha: 0.1)
        : AppColors.iconBackground;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(color: titleColor),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.settingsBodySmall.copyWith(color: AppColors.secondaryText)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg, // Approx to contain splash
        child: content,
      );
    }

    if (showDivider) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          const Padding(
            padding: EdgeInsets.only(left: 76), // Align with text
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.gray100,
            ),
          ),
        ],
      );
    }

    return content;
  }
}

/// Settings item for account status (e.g. Active with green dot).
class SettingStatusItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String statusText;
  final Color statusColor;
  final bool showDivider;

  const SettingStatusItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingItemBase(
      icon: icon,
      title: title,
      subtitle: subtitle,
      showDivider: showDivider,
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              statusText,
              style: AppTextStyles.settingsLabel.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings item with a copy button for referral code etc.
class SettingCopyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String valueText;
  final VoidCallback onCopy;
  final bool showDivider;

  const SettingCopyItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.valueText,
    required this.onCopy,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingItemBase(
      icon: icon,
      title: title,
      subtitle: subtitle,
      showDivider: showDivider,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valueText,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryText),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            icon: const Icon(Icons.copy_rounded,
                size: 18, color: AppColors.iconColor),
            onPressed: onCopy,
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Settings item with a toggle switch.
class SettingToggleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const SettingToggleItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingItemBase(
      icon: icon,
      title: title,
      subtitle: subtitle,
      showDivider: showDivider,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.surface,
        activeTrackColor: AppColors.toggleRed,
        inactiveThumbColor: AppColors.surface,
        inactiveTrackColor: AppColors.dividerColor,
      ),
    );
  }
}

/// Settings item for navigation with a right arrow.
class SettingNavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? valueText;
  final VoidCallback onTap;
  final bool showDivider;
  final bool isDestructive;

  const SettingNavItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.valueText,
    required this.onTap,
    this.showDivider = true,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SettingItemBase(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      isDestructive: isDestructive,
      showDivider: showDivider,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (valueText != null) ...[
            Text(valueText!, style: AppTextStyles.settingsBodySmall.copyWith(color: AppColors.secondaryText)),
            const SizedBox(width: AppSpacing.xs),
          ],
          Icon(
            Icons.chevron_right_rounded,
            color:
                isDestructive ? AppColors.danger : AppColors.secondaryText,
            size: 20,
          ),
        ],
      ),
    );
  }
}
