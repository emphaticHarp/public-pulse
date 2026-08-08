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

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("📱 ProfilePage Build");
    final controller = ProfileController.to;

    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDefault,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.textPrimary,
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 4),
        ],
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
                    profileImage: resolveProfileImage(url: controller.avatarUrl),
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
                      videoPosts: controller.videoPosts,
                      savedPosts: controller.savedPosts,
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
  final List<String> photoPosts;
  final List<String> videoPosts;
  final List<String> savedPosts;

  const _TabContent({
    required this.tab,
    required this.photoPosts,
    required this.videoPosts,
    required this.savedPosts,
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
          savedPosts,
          Icons.bookmark_border,
          'No saved posts yet',
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