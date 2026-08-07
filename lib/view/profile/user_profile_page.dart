import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/user_profile_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_font.dart';
import '../../model/profile_model.dart';
import '../../widget/profile/profile_widget.dart';

/// Displays a public user profile. Reuses all shared profile widgets;
/// the only difference from [ProfilePage] is the action buttons row.
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: Get.back,
        ),
      ),
      // Single top-level Obx only for the loading gate; inner widgets use
      // their own targeted Obx so only the changing piece rebuilds.
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

// ── Static profile body — rebuilt only when isLoading flips to false ──────────

class _ProfileBody extends StatelessWidget {
  final UserProfileController controller;

  const _ProfileBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Read once; profile is non-null here (gate checked in Obx above).
    final profile = controller.profile.value!;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header images are static after load — no Obx needed.
            ProfileHeaderImage(
              coverImage: resolveProfileImage(url: controller.coverUrl),
              profileImage: resolveProfileImage(url: controller.avatarUrl),
            ),
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.only(left: 130, right: 15),
                // Single Obx covers both counts so only one subscription is
                // created instead of two separate Obx wrappers.
                child: Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ProfileStatColumn(
                        count: 0, // Wire to post count when Posts feature lands.
                        label: 'Posts',
                      ),
                      GestureDetector(
                        onTap: () => controller.openFollowersFollowing(0),
                        behavior: HitTestBehavior.opaque,
                        child: ProfileStatColumn(
                          count: controller.followerCount.value,
                          label: 'Followers',
                        ),
                      ),
                      GestureDetector(
                        onTap: () => controller.openFollowersFollowing(1),
                        behavior: HitTestBehavior.opaque,
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

                  // ── Action buttons: Follow/Unfollow + Message ─────────
                  _ActionButtons(controller: controller),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => ProfileTabSelector(
                selected: controller.selectedTab.value,
                onChanged: controller.changeTab,
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Obx(
              () => _TabContent(
                tab: controller.selectedTab.value,
                photoPosts: controller.photoPosts,
                videoPosts: controller.videoPosts,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action buttons row (Follow / Unfollow + Message) ──────────────────────────

class _ActionButtons extends StatelessWidget {
  final UserProfileController controller;

  const _ActionButtons({required this.controller});

  @override
  Widget build(BuildContext context) => Obx(
        () => Row(
          children: [
            Expanded(
              child: AppPrimaryButton(
                label: controller.isFollowing.value ? 'Unfollow' : 'Follow',
                loading: controller.isFollowLoading.value,
                onTap: controller.toggleFollow,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppOutlinedButton(
                label: 'Message',
                icon: Icons.mail_outline,
                onTap: () {}, // Wire to messaging feature when available.
              ),
            ),
          ],
        ),
      );
}

// ── Tab content grid ──────────────────────────────────────────────────────────

class _TabContent extends StatelessWidget {
  final ProfileTab tab;
  final List<String> photoPosts;
  final List<String> videoPosts;

  const _TabContent({
    required this.tab,
    required this.photoPosts,
    required this.videoPosts,
  });

  @override
  Widget build(BuildContext context) {
    final (urls, icon, emptyMessage) = switch (tab) {
      ProfileTab.photos => (photoPosts, Icons.photo_outlined, 'No photos yet'),
      ProfileTab.videos => (
          videoPosts,
          Icons.videocam_outlined,
          'No videos yet',
        ),
      ProfileTab.saved => (
          <String>[],
          Icons.lock_outline,
          'Saved posts are private',
        ),
    };

    if (urls.isEmpty) {
      return ProfileEmptyState(icon: icon, message: emptyMessage);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: urls.length,
      itemBuilder: (context, i) => Image.network(urls[i], fit: BoxFit.cover),
    );
  }
}
