import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';

import 'package:get/get.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/widget/local/app_alert.dart';
import 'package:public_pulse/widget/post/follow_button.dart';
import 'package:public_pulse/view/profile/user_profile_page.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:public_pulse/core/cache/image_cache_key.dart';

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

  @override
  Widget build(BuildContext context) {
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
                          if (isOwner) return;

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

                          backgroundImage: profileImage.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  profileImage,
                                  cacheKey: supabaseStorageCacheKey(
                                    profileImage,
                                  ),
                                )
                              : null,

                          child: profileImage.isEmpty
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (isOwner) return;

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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),

                                FollowButton(
                                  profileId: authorId,
                                  isOwner: isOwner,
                                ),
                              ],
                            ),

                            if (location != null && location!.trim().isNotEmpty)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: AppColors.gray500,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    location!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  elevation: 12,
                  color: Colors.white,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  position: PopupMenuPosition.under,
                  splashRadius: 20,
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.gray700,
                      size: 20,
                    ),
                  ),

                  onSelected: (value) async {
                    if (value == "delete") {
                      final controller = Get.find<HomeController>();
                      final confirmed = await CustomAlert.showConfirm(
                        title: 'Delete Post?',
                        message: 'This post will be permanently removed.',
                        icon: Icons.delete_outline_rounded,
                        color: Colors.red,
                        confirmText: 'Delete',
                      );
                      if (confirmed) {
                        await controller.deletePost(postId);
                      }
                    }

                    if (value == "report") {
                      CustomAlert.show(
                        title: 'Report',
                        message: 'Report feature coming soon',
                        icon: Icons.flag_outlined,
                        color: Colors.orange,
                      );
                    }

                    if (value == "block") {
                      CustomAlert.show(
                        title: 'Block',
                        message: 'Block feature coming soon',
                        icon: Icons.block_outlined,
                        color: Colors.red,
                      );
                    }

                    if (value == "unfollow") {
                      CustomAlert.show(
                        title: 'Unfollow',
                        message: 'Unfollow feature coming soon',
                        icon: Icons.person_remove_outlined,
                        color: Colors.blue,
                      );
                    }
                  },

                  itemBuilder: (context) {
                    if (isOwner) {
                      return [
                        PopupMenuItem<String>(
                          value: "delete",
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Delete Post",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ];
                    }

                    return [
                      const PopupMenuItem(
                        value: "report",
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined, color: Colors.orange),
                            SizedBox(width: 10),
                            Text("Report"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: "block",
                        child: Row(
                          children: [
                            Icon(Icons.block_outlined, color: Colors.red),
                            SizedBox(width: 10),
                            Text("Block"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: "unfollow",
                        child: Row(
                          children: [
                            Icon(Icons.person_remove_outlined),
                            SizedBox(width: 10),
                            Text("Unfollow"),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
