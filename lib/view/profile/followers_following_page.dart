import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:public_pulse/controller/followers_following_controller.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/core/theme/app_font.dart';
import 'package:public_pulse/model/profile_model.dart';
import 'package:public_pulse/widget/profile/user_list_tile.dart';
import 'package:public_pulse/view/profile/user_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/view/profile/profile_page.dart';

class FollowersFollowingPage extends StatelessWidget {
  final int initialTab;
  final String? controllerTag;

  const FollowersFollowingPage({
    super.key,
    this.initialTab = 0,
    this.controllerTag,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FollowersFollowingController>(
      tag: controllerTag,
    );

    return Scaffold(
      backgroundColor: AppColors.warmLightBg,

      // =========================================================
      // APP BAR
      // =========================================================
      appBar: AppBar(
        backgroundColor: AppColors.warmLightBg,

        elevation: 0,
        centerTitle: false,

        title: Text(
          'Followers & Following',
          style: AppTextStyles.sectionHeading.copyWith(
            color: AppColors.darkNearBlack,
          ),
        ),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: Get.back,
        ),

        // =======================================================
        // TAB BAR
        // =======================================================
        bottom: TabBar(
          controller: controller.tabController,

          indicatorColor: AppColors.brand,
          indicatorWeight: 2,

          labelColor: AppColors.brand,
          unselectedLabelColor: AppColors.textSecondary,

          labelStyle: AppTextStyles.tabLabelActive,

          unselectedLabelStyle: AppTextStyles.tabLabel,

          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),

      // =========================================================
      // TAB CONTENT
      // =========================================================
      body: TabBarView(
        controller: controller.tabController,

        children: [
          // -----------------------------------------------------
          // FOLLOWERS
          // -----------------------------------------------------

          _UserList(
            users: controller.followers,
            isLoading: controller.isLoadingFollowers,
            emptyMessage: 'No followers yet',
            controllerTag: controllerTag,
          ),

          // -----------------------------------------------------
          // FOLLOWING
          // -----------------------------------------------------
          _UserList(
            users: controller.following,
            isLoading: controller.isLoadingFollowing,
            emptyMessage: 'Not following anyone yet',
            controllerTag: controllerTag,
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// USER LIST
// ===============================================================

class _UserList extends StatelessWidget {
  final RxList<FollowerModel> users;
  final RxBool isLoading;
  final String emptyMessage;
  final String? controllerTag;

  const _UserList({
    required this.users,
    required this.isLoading,
    required this.emptyMessage,
    required this.controllerTag,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = isLoading.value;

      // Copy RxList into normal list.
      final list = users.toList();

      // =========================================================
      // FIRST LOADING
      // =========================================================

      if (loading && list.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        );
      }

      // =========================================================
      // EMPTY
      // =========================================================

      if (!loading && list.isEmpty) {
        return RefreshIndicator(
          color: AppColors.brand,

          onRefresh: () {
            return Get.find<FollowersFollowingController>(
              tag: controllerTag,
            ).refreshList();
          },

          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),

            children: [
              SizedBox(
                height: 400,

                child: Center(
                  child: Text(
                    emptyMessage,

                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // =========================================================
      // USERS
      // =========================================================

      return RefreshIndicator(
        color: AppColors.brand,

        onRefresh: () {
          return Get.find<FollowersFollowingController>(
            tag: controllerTag,
          ).refreshList();
        },

        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),

          itemCount: list.length,

          separatorBuilder: (context, index) {
            return const Divider(height: 1, color: AppColors.divider);
          },

          itemBuilder: (context, index) {
            final user = list[index];

            return UserListTile(
              user: user,

              onTap: () {
                if (user.userId.isEmpty) {
                  debugPrint('[FF_DEBUG] Cannot open profile: userId empty');
                  return;
                }

                final currentUserId =
                    Supabase.instance.client.auth.currentUser?.id;

                // If this row is my own account → open my normal ProfilePage
                if (currentUserId != null && user.userId == currentUserId) {
                  Get.to(() => const ProfilePage());
                  return;
                }

                // Otherwise open other user's public profile
                Get.to(() => UserProfilePage(userId: user.userId));
              },
            );
          },
        ),
      );
    });
  }
}
