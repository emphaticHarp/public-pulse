import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/profile_controller.dart';
import '../../controller/edit_profile_controller.dart';
import '../../controller/setting_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_font.dart';
import '../../model/profile_model.dart';
import '../../widget/profile/profile_widget.dart';
import '../../view/setting/setting_page.dart';
import 'edit_profile.dart';
import '../../model/post_model.dart';
import '../../view/post/post_detail_page.dart';

class ProfilePage extends StatelessWidget {
  final String? userId;

  /// True only when my own profile is opened from Explore.
  final bool openedFromExplore;

  const ProfilePage({super.key, this.userId, this.openedFromExplore = false});

  @override
  Widget build(BuildContext context) {
    debugPrint("📱 ProfilePage Build");
    final tag = userId ?? 'my_profile';

    if (!Get.isRegistered<ProfileController>(tag: tag)) {
      Get.put(ProfileController(userId: userId), tag: tag, permanent: false);
    }

    final controller = Get.find<ProfileController>(tag: tag);

    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDefault,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,

        // ============================================================
        // BACK BUTTON
        // Only when own profile was opened from Explore
        // ============================================================
        automaticallyImplyLeading: false,

        leading: openedFromExplore
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                tooltip: 'Back',
                onPressed: () {
                  Get.back();
                },
              )
            : null,

        // ============================================================
        // SETTINGS
        // Show only on normal Profile tab
        // ============================================================
        actions: userId == null && !openedFromExplore
            ? [
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.textPrimary,
                  ),
                  tooltip: 'Settings',
                  onPressed: _openSettings,
                ),
                const SizedBox(width: 4),
              ]
            : [],
      ),
      body: Obx(() {
        final profile = controller.profile.value;
        if (controller.isLoading.value || profile == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.brand),
          );
        }

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeaderImage(
                    coverImage: resolveProfileImage(url: controller.coverUrl),
                    profileImage: resolveProfileImage(
                      url: controller.avatarUrl,
                    ),
                  ),
                  const SizedBox(height: 0),
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 130, right: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ProfileStatColumn(
                            count: controller.postCount.value,
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
                        if (userId == null)
                          AppOutlinedButton(
                            label: 'Edit Profile',
                            icon: Icons.edit_outlined,
                            onTap: () => _openEditProfile(),
                          ),
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
                      savedPosts: controller.savedPosts,
                      isPostsLoading: controller.isPostsLoading.value,
                      isSavedPostsLoading: controller.isSavedPostsLoading.value,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _openEditProfile() {
    Get.delete<EditProfileController>(force: true);
    Get.put(EditProfileController());
    Get.to(() => const EditProfilePage());
  }

  void _openSettings() {
    if (!Get.isRegistered<SettingController>()) {
      Get.put(SettingController());
    }
    Get.to(() => const SettingPage());
  }
}

class _TabContent extends StatelessWidget {
  final ProfileTab tab;
  final List<PostModel> photoPosts;
  final List<PostModel> savedPosts;

  final bool isPostsLoading;
  final bool isSavedPostsLoading;

  const _TabContent({
    required this.tab,
    required this.photoPosts,
    required this.savedPosts,
    required this.isPostsLoading,
    required this.isSavedPostsLoading,
  });

  @override
  Widget build(BuildContext context) {
    final posts = switch (tab) {
      ProfileTab.photos => photoPosts,
      ProfileTab.saved => savedPosts,
    };

    final loading = switch (tab) {
      ProfileTab.photos => isPostsLoading,
      ProfileTab.saved => isSavedPostsLoading,
    };

    final icon = switch (tab) {
      ProfileTab.photos => Icons.photo_outlined,
      ProfileTab.saved => Icons.bookmark_border,
    };

    final emptyMessage = switch (tab) {
      ProfileTab.photos => 'No photos yet',
      ProfileTab.saved => 'No saved posts yet',
    };

    // --------------------------------------------------
    // LOADING
    // --------------------------------------------------

    if (loading && posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.brand)),
      );
    }

    // --------------------------------------------------
    // EMPTY
    // --------------------------------------------------

    if (!loading && posts.isEmpty) {
      return ProfileEmptyState(icon: icon, message: emptyMessage);
    }

    // --------------------------------------------------
    // POSTS
    // --------------------------------------------------

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];

        if (post.mediaUrls.isEmpty) {
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.image_not_supported_outlined),
            ),
          );
        }

        // Tap → open Post Detail with the exact PostModel, zero re-fetch.
        return GestureDetector(
          onTap: () => Get.to(() => PostDetailPage(post: post)),
          child: Image.network(
            post.mediaUrls.first,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('[PROFILE IMAGE ERROR] ${post.mediaUrls.first}');
              return Container(
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.broken_image_outlined)),
              );
            },
          ),
        );
      },
    );
  }
}
