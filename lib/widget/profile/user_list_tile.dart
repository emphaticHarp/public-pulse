import 'package:flutter/material.dart';
import '../../core/repository/profile_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_font.dart';
import '../../model/profile_model.dart';
import 'profile_widget.dart';

/// Reusable list tile for a single follower or following entry.
class UserListTile extends StatelessWidget {
  final FollowerModel user;
  final VoidCallback? onTap;

  const UserListTile({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarPath != null
        ? ProfileRepository.instance.resolveUrl(user.avatarPath!, bucket: 'avatars')
        : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ProfileAvatar(
              image: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (user.displayName?.isNotEmpty ?? false)
                        ? user.displayName!
                        : user.username,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${user.username}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
