import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/profile_controller.dart';
import '../../controller/edit_profile_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_font.dart';
import '../../model/profile_model.dart';
import '../../widget/profile/profile_widget.dart';
import 'edit_profile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProfileController.to;

    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      body: Obx(() {
        final profile = controller.profile.value;
        if (controller.isLoading.value || profile == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.brand),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeaderImage(
                  coverImage: resolveProfileImage(url: profile.coverPhotoUrl),
                  profileImage: resolveProfileImage(
                    url: profile.profilePhotoUrl,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ProfileStatColumn(
                        count: profile.postsCount,
                        label: 'Posts',
                      ),
                      ProfileStatColumn(
                        count: profile.followersCount,
                        label: 'Followers',
                      ),
                      ProfileStatColumn(
                        count: profile.followingCount,
                        label: 'Following',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                          if (profile.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified,
                              color: AppColors.brand,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${profile.username}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if ((profile.bio ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          profile.bio!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
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
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _openEditProfile() {
    Get.put(EditProfileController());
    Get.to(
      () => const EditProfilePage(),
    )?.whenComplete(() => Get.delete<EditProfileController>());
  }
}

class _TabContent extends StatelessWidget {
  final ProfileTab tab;
  final List<String> photoPosts;
  final List<String> savedPosts;

  const _TabContent({
    required this.tab,
    required this.photoPosts,
    required this.savedPosts,
  });

  @override
  Widget build(BuildContext context) {
    final (urls, icon, emptyMessage) = switch (tab) {
      ProfileTab.photos => (photoPosts, Icons.photo_outlined, 'No photos yet'),
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
