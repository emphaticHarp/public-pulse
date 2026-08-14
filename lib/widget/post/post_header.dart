import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/widget/local/app_alert.dart';
import 'package:public_pulse/widget/post/follow_button.dart';
import 'package:public_pulse/view/profile/user_profile_page.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:public_pulse/core/cache/image_cache_key.dart';
import 'package:public_pulse/view/profile/profile_page.dart';

class PostHeader extends StatelessWidget {
  final String profileImage;
  final String username;
  final String authorId;
  final String authorUserId;
  final String? location;
  final String postId;
  final bool isOwner;
  final VoidCallback? onDelete;

  const PostHeader({
    super.key,
    required this.profileImage,
    required this.username,
    required this.authorId,
    required this.authorUserId,
    this.location,
    required this.postId,
    required this.isOwner,
    this.onDelete,
  });

  String _resolveAvatarUrl(String value) {
    final avatar = value.trim();

    if (avatar.isEmpty) {
      return '';
    }

    // Google / external avatar
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return avatar;
    }

    // Supabase Storage avatar
    return Supabase.instance.client.storage
        .from('avatars')
        .getPublicUrl(avatar);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    final isMyPost = currentUserId != null && authorUserId == currentUserId;

    final avatarUrl = _resolveAvatarUrl(profileImage);

    final HomeController homeController = Get.find<HomeController>();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // My own post → open my profile page.
                          if (isMyPost) {
                            Get.to(() => const ProfilePage());
                            return;
                          }
                          // Other user's post → open their public profile.
                          if (authorUserId.isEmpty) {
                            debugPrint(
                              '[POST_HEADER] authorUserId is empty. Cannot open profile.',
                            );
                            return;
                          }

                          Get.to(() => UserProfilePage(userId: authorUserId));
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.gray100,

                          backgroundImage: avatarUrl.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  avatarUrl,
                                  cacheKey:
                                      avatarUrl.startsWith(
                                        'https://lh3.googleusercontent.com',
                                      )
                                      ? avatarUrl
                                      : supabaseStorageCacheKey(avatarUrl),
                                )
                              : null,

                          child: avatarUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: AppColors.gray400,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ======================================================
                            // USERNAME + LOCATION
                            // ======================================================
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      // My own post → open my profile.
                                      if (isMyPost) {
                                        Get.to(() => const ProfilePage());
                                        return;
                                      }

                                      // Other user's post → open their profile.
                                      if (authorUserId.isEmpty) {
                                        debugPrint(
                                          '[POST_HEADER] authorUserId is empty. Cannot open profile.',
                                        );
                                        return;
                                      }

                                      Get.to(
                                        () => UserProfilePage(
                                          userId: authorUserId,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      username,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),

                                  if (location != null &&
                                      location!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 2),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: AppColors.gray500,
                                        ),
                                        const SizedBox(width: 2),

                                        Expanded(
                                          child: Text(
                                            location!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.gray500,
                                              height: 1.1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // ======================================================
                            // FOLLOW BUTTON
                            // ======================================================
                            FollowButton(
                              profileId: authorId,
                              isOwner: isMyPost,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  final bool isFollowing = homeController.followingIds.contains(
                    authorId,
                  );

                  return PopupMenuButton<String>(
                    elevation: 12,
                    color: AppColors.white,
                    shadowColor: AppColors.shadowBlack26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    position: PopupMenuPosition.under,
                    splashRadius: 20,

                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.greyShade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        color: AppColors.gray700,
                        size: 20,
                      ),
                    ),

                    // ==========================================================
                    // MENU ACTIONS
                    // ==========================================================
                    onSelected: (value) async {
                      // --------------------------------------------------------
                      // DELETE
                      // --------------------------------------------------------

                      if (value == 'delete') {
                        final confirmed = await CustomAlert.showConfirm(
                          title: 'Delete Post?',
                          message: 'This post will be permanently removed.',
                          icon: Icons.delete_outline_rounded,
                          color: AppColors.semanticRed,
                          confirmText: 'Delete',
                        );

                        if (confirmed) {
                          await homeController.deletePost(postId);
                        }

                        return;
                      }

                      // --------------------------------------------------------
                      // REPORT
                      // --------------------------------------------------------

                      if (value == 'report') {
                        CustomAlert.show(
                          title: 'Report',
                          message: 'Report feature coming soon',
                          icon: Icons.flag_outlined,
                          color: AppColors.semanticOrange,
                        );

                        return;
                      }

                      // --------------------------------------------------------
                      // BLOCK
                      // --------------------------------------------------------

                      if (value == 'block') {
                        CustomAlert.show(
                          title: 'Block',
                          message: 'Block feature coming soon',
                          icon: Icons.block_outlined,
                          color: AppColors.semanticRed,
                        );

                        return;
                      }

                      // --------------------------------------------------------
                      // UNFOLLOW
                      // --------------------------------------------------------

                      if (value == 'unfollow') {
                        await homeController.unfollowUser(authorId);
                        return;
                      }
                    },

                    // ==========================================================
                    // MENU ITEMS
                    // ==========================================================
                    itemBuilder: (context) {
                      // --------------------------------------------------------
                      // MY OWN POST
                      // --------------------------------------------------------

                      if (isOwner) {
                        return const [
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.semanticRed,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Delete Post',
                                  style: TextStyle(
                                    color: AppColors.semanticRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ];
                      }

                      // --------------------------------------------------------
                      // OTHER USER POST
                      // --------------------------------------------------------

                      return [
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined, color: AppColors.semanticOrange),
                              SizedBox(width: 10),
                              Text('Report'),
                            ],
                          ),
                        ),

                        const PopupMenuItem<String>(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block_outlined, color: AppColors.semanticRed),
                              SizedBox(width: 10),
                              Text('Block'),
                            ],
                          ),
                        ),

                        // Only show Unfollow when currently following.
                        if (isFollowing)
                          const PopupMenuItem<String>(
                            value: 'unfollow',
                            child: Row(
                              children: [
                                Icon(Icons.person_remove_outlined),
                                SizedBox(width: 10),
                                Text('Unfollow'),
                              ],
                            ),
                          ),
                      ];
                    },
                  );
                }),
              ], //----------------------------------
            ),
          ),
        ],
      ),
    );
  }
}
