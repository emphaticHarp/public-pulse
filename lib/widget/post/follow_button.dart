import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/core/theme/app_colors.dart';

class FollowButton extends StatelessWidget {
  final String profileId;
  final bool isOwner;

  const FollowButton({
    super.key,
    required this.profileId,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    // Don't show Follow button on your own posts
    if (isOwner) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final bool isFollowing = controller.followingIds.contains(profileId);

      if (isFollowing) {
        return OutlinedButton(
          onPressed: () async {
            await controller.unfollowUser(profileId);
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(95, 34),
            backgroundColor: AppColors.grayshade200,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            "Following",
            style: TextStyle(
              color: AppColors.gray600,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }

      return ElevatedButton(
        onPressed: () async {
          await controller.followUser(profileId);
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(95, 34),
          backgroundColor: AppColors.loginAccentRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          "Follow",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    });
  }
}