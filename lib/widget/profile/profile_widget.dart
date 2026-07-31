import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_font.dart';
import '../../model/profile_model.dart';

/// Shared by [AppOutlinedButton] and [AppPrimaryButton] so the padding and
/// corner radius are defined once instead of repeated per button.
const _buttonPadding = EdgeInsets.symmetric(vertical: 14);
final _buttonShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(10),
);

/// Resolves a freshly picked local [file] (priority) or an already-saved
/// remote [url] into a single [ImageProvider]. Used by both pages so image
/// resolution logic exists in exactly one place.
ImageProvider? resolveProfileImage({File? file, String? url}) {
  if (file != null) return FileImage(file);
  if (url != null && url.isNotEmpty) return NetworkImage(url);
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
  final double size;

  const ChangePhotoButton({super.key, required this.onTap, this.size = 34});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        color: AppColors.pureBlack,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.camera_alt_outlined,
        color: AppColors.primaryWhite,
        size: size * 0.5,
      ),
    ),
  );
}

/// Cover photo + floating circular avatar. Shared by Profile Screen (no
/// actions) and Edit Profile Screen ([coverAction] / [avatarAction] set),
/// so the header is built in exactly one place.
class ProfileHeaderImage extends StatelessWidget {
  final ImageProvider? coverImage;
  final ImageProvider? profileImage;
  final Widget? coverAction;
  final Widget? avatarAction;

  const ProfileHeaderImage({
    super.key,
    required this.coverImage,
    required this.profileImage,
    this.coverAction,
    this.avatarAction,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 220,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 170,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.brand,
            image: coverImage != null
                ? DecorationImage(image: coverImage!, fit: BoxFit.cover)
                : null,
          ),
        ),
        if (coverAction != null)
          Positioned(right: 16, bottom: 62, child: coverAction!),
        Positioned(
          left: 20,
          top: 130,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ProfileAvatar(image: profileImage),
              if (avatarAction != null)
                Positioned(right: 0, bottom: 0, child: avatarAction!),
            ],
          ),
        ),
      ],
    ),
  );
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
      final color = isActive ? AppColors.brand : AppColors.textSecondary;
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
                color: isActive ? AppColors.brand : AppColors.transparent,
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
    child: Column(
      children: [
        Icon(icon, size: 56, color: AppColors.gray400),
        const SizedBox(height: 12),
        Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray400),
        ),
      ],
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
      backgroundColor: AppColors.brand,
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
