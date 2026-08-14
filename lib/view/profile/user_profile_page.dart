import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/user_profile_controller.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_font.dart';

import '../../model/post_model.dart';
import '../../widget/profile/profile_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/cache/image_cache_key.dart';
import '../post/post_detail_page.dart';

class UserProfilePage extends StatelessWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      UserProfileController(userId: userId),
      tag: userId,
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,

      appBar: AppBar(
        backgroundColor: AppColors.surfaceDefault,
        surfaceTintColor: AppColors.transparentFull,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: Get.back,
        ),
      ),

      body: Obx(() {
        if (controller.isLoading.value || controller.profile.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.brand),
          );
        }

        return _ProfileBody(controller: controller);
      }),
    );
  }
}

// ─────────────────────────────────────────────
// PROFILE BODY
// ─────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final UserProfileController controller;

  const _ProfileBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile.value!;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────
            // HEADER
            // ─────────────────────────────────
            ProfileHeaderImage(
              coverImage: resolveProfileImage(url: controller.coverUrl),
              profileImage: resolveProfileImage(url: controller.avatarUrl),
            ),

            // ─────────────────────────────────
            // STATS
            // ─────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -30),

              child: Padding(
                padding: const EdgeInsets.only(left: 130, right: 15),

                child: Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                    children: [
                      ProfileStatColumn(
                        count: profile.postCount ?? 0,
                        label: 'Posts',
                      ),

                      GestureDetector(
                        behavior: HitTestBehavior.opaque,

                        onTap: () => controller.openFollowersFollowing(0),

                        child: ProfileStatColumn(
                          count: controller.followerCount.value,
                          label: 'Followers',
                        ),
                      ),

                      GestureDetector(
                        behavior: HitTestBehavior.opaque,

                        onTap: () => controller.openFollowersFollowing(1),

                        child: ProfileStatColumn(
                          count: controller.followingCount.value,
                          label: 'Following',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 3),

            // ─────────────────────────────────
            // PROFILE INFORMATION
            // ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          (profile.displayName?.isNotEmpty ?? false)
                              ? profile.displayName!
                              : profile.username,

                          style: AppTextStyles.loginHeading.copyWith(
                            color: AppColors.textPrimary,
                          ),

                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '@${profile.username}',

                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if ((profile.bio ?? '').isNotEmpty)
                    Text(
                      profile.bio!,

                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),

                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    const SizedBox(height: 20),

                  const SizedBox(height: 8),

                  // ───────────────────────────
                  // FOLLOW / MESSAGE
                  // ───────────────────────────
                  _ActionButtons(controller: controller),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─────────────────────────────────
            // TABS
            // ─────────────────────────────────
            const Divider(height: 1, color: AppColors.divider),

            // ─────────────────────────────────
            // POST GRID
            // ─────────────────────────────────
            Obx(() => _TabContent(photoPosts: controller.photoPosts.toList())),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACTION BUTTONS
// ─────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final UserProfileController controller;

  const _ActionButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: AppPrimaryButton(
              label: controller.followButtonLabel,
              loading: controller.isFollowLoading.value,
              onTap: controller.toggleFollow,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: AppOutlinedButton(
              label: 'Message',
              icon: Icons.mail_outline,
              onTap: () {
                // Messaging feature later.
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB CONTENT (POST GRID)
// ─────────────────────────────────────────────

class _TabContent extends StatelessWidget {
  final List<PostModel> photoPosts;

  const _TabContent({required this.photoPosts});

  @override
  Widget build(BuildContext context) {
    if (photoPosts.isEmpty) {
      return const ProfileEmptyState(
        icon: Icons.photo_outlined,
        message: 'No posts yet',
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      itemCount: photoPosts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        final post = photoPosts[index];

        if (post.mediaUrls.isEmpty) {
          return Container(
            color: AppColors.surfaceDefault,
            child: const Center(
              child: Icon(Icons.image_not_supported_outlined),
            ),
          );
        }

        // Tap → open Post Detail with the full PostModel, zero re-fetch.
        return GestureDetector(
          onTap: () => Get.to(() => PostDetailPage(post: post)),
          child: CachedNetworkImage(
            imageUrl: post.mediaUrls.first,
            cacheKey: supabaseStorageCacheKey(post.mediaUrls.first),
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (context, url) =>
                Container(color: AppColors.surfaceDefault),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surfaceDefault,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }
}
