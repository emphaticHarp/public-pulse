import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_font.dart';
import '../../model/profile_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/cache/image_cache_key.dart';

/// Shared by [AppOutlinedButton] and [AppPrimaryButton] so the padding and
/// corner radius are defined once instead of repeated per button.
const _buttonPadding = EdgeInsets.symmetric(vertical: 14);
final _buttonShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(10),
);

ImageProvider? resolveProfileImage({File? file, String? url}) {
  if (file != null) {
    return FileImage(file);
  }

  if (url != null && url.isNotEmpty) {
    return CachedNetworkImageProvider(
      url,
      cacheKey: supabaseStorageCacheKey(url),
    );
  }

  return null;
}

class ProfileAvatar extends StatelessWidget {
  final ImageProvider? image;
  final double radius;

  const ProfileAvatar({super.key, this.image, this.radius = 48});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: const BoxDecoration(
      color: AppColors.primaryWhite,
      shape: BoxShape.circle,
    ),
    child: CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.gray100,
      backgroundImage: image,
      child: image == null
          ? Icon(Icons.person, size: radius, color: AppColors.gray400)
          : null,
    ),
  );
}

class ChangePhotoButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool circular;

  const ChangePhotoButton({
    super.key,
    required this.onTap,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparentFull,
      child: InkWell(
        onTap: onTap,
        customBorder: circular ? const CircleBorder() : null,
        child: Container(
          decoration: BoxDecoration(
            // Very light full-image overlay.
            color: AppColors.overlayBlack18.withValues(alpha: 0.10),
            shape: circular ? BoxShape.circle : BoxShape.rectangle,
          ),
          alignment: Alignment.center,

          // Frosted / blurred camera button.
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.22),
                  shape: BoxShape.circle,

                  // Softer border instead of sharp white.
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cover photo + floating circular avatar. Shared by Profile Screen and Edit Profile Screen
class ProfileHeaderImage extends StatelessWidget {
  final ImageProvider? coverImage;
  final ImageProvider? profileImage;
  final Widget? coverAction;
  final Widget? avatarAction;

  /// Optional icon overlaid on the cover — top-left
  final Widget? leadingAction;

  /// Optional icon overlaid on the cover — top-right
  final Widget? trailingAction;

  const ProfileHeaderImage({
    super.key,
    required this.coverImage,
    required this.profileImage,
    this.coverAction,
    this.avatarAction,
    this.leadingAction,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ─────────────────────────────────────
          // COVER IMAGE
          // ─────────────────────────────────────
          SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: AppColors.gray100,
                  child: coverImage != null
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: coverImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 46,
                            color: AppColors.gray400,
                          ),
                        ),
                ),

                // Full cover overlay.
                if (coverAction != null)
                  Positioned.fill(child: ClipRect(child: coverAction!)),
              ],
            ),
          ),

          // ─────────────────────────────────────
          // ICON OVERLAYS (settings / back)
          // ─────────────────────────────────────
          if (leadingAction != null) leadingAction!,
          if (trailingAction != null) trailingAction!,

          // ─────────────────────────────────────
          // PROFILE IMAGE
          // ─────────────────────────────────────
          Positioned(
            left: 20,
            top: 130,
            child: SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProfileAvatar(image: profileImage, radius: 48),

                  // Full circular avatar overlay.
                  if (avatarAction != null)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ClipOval(child: avatarAction!),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileStatColumn extends StatelessWidget {
  final int count;
  final String label;

  const ProfileStatColumn({
    super.key,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        '$count',
        style: AppTextStyles.sectionHeading.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    ],
  );
}

class ProfileTabSelector extends StatelessWidget {
  final ProfileTab selected;
  final ValueChanged<ProfileTab> onChanged;

  const ProfileTabSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _labels = {
    ProfileTab.photos: 'Photos',
    ProfileTab.saved: 'Saved',
  };

  @override
  Widget build(BuildContext context) => Row(
    children: ProfileTab.values.map((tab) {
      final isActive = tab == selected;
      final color = isActive
          ? AppColors.loginAccentRed
          : AppColors.textSecondary;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(tab),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _labels[tab]!,
                  style:
                      (isActive
                              ? AppTextStyles.tabLabelActive
                              : AppTextStyles.tabLabel)
                          .copyWith(color: color),
                ),
              ),
              Container(
                height: 2,
                color: isActive
                    ? AppColors.loginAccentRed
                    : AppColors.transparent,
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}

class ProfileEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const ProfileEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 64),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.gray400),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray400),
          ),
        ],
      ),
    ),
  );
}

/// Full-width outlined button. Used for "Edit Profile" and "Cancel".
class AppOutlinedButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const AppOutlinedButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppColors.slate200),
      padding: _buttonPadding,
      shape: _buttonShape,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: AppTextStyles.buttonText.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

/// Full-width filled brand button with a built-in loading state. Used for
/// "Save" so the spinner-vs-label logic isn't duplicated per screen.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: loading ? null : onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.loginAccentRed,
      padding: _buttonPadding,
      shape: _buttonShape,
    ),
    child: loading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryWhite,
            ),
          )
        : Text(
            label,
            style: AppTextStyles.buttonText.copyWith(
              color: AppColors.primaryWhite,
            ),
          ),
  );
}
