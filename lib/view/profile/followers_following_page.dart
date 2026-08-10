import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/followers_following_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_font.dart';
import '../../widget/profile/user_list_tile.dart';

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

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 246, 241, 239),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 246, 241, 239),
          elevation: 0,
          centerTitle: false,

          title: Text(
            'Followers & Following',
            style: AppTextStyles.sectionHeading.copyWith(
              color: const Color.fromARGB(255, 22, 22, 23),
            ),
          ),

          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: Get.back,
          ),

          bottom: _FFTabBar(onTabChanged: controller.switchTab),
        ),

        body: TabBarView(
          children: [
            // FOLLOWERS
            _UserList(
              isLoading: controller.isLoadingFollowers,
              users: controller.followers,
              emptyMessage: 'No followers yet',
              controllerTag: controllerTag,
            ),
            // FOLLOWING
            _UserList(
              isLoading: controller.isLoadingFollowing,
              users: controller.following,
              emptyMessage: 'Not following anyone yet',
              controllerTag: controllerTag,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB BAR
// ─────────────────────────────────────────────

class _FFTabBar extends StatelessWidget implements PreferredSizeWidget {
  final ValueChanged<int> onTabChanged;

  const _FFTabBar({required this.onTabChanged});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      onTap: onTabChanged,

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
    );
  }
}

// ─────────────────────────────────────────────
// USER LIST
// ─────────────────────────────────────────────

class _UserList extends StatelessWidget {
  final RxBool isLoading;
  final RxList users;
  final String emptyMessage;
  final String? controllerTag;

  const _UserList({
    required this.isLoading,
    required this.users,
    required this.emptyMessage,
    this.controllerTag,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = isLoading.value;
      final list = users;

      // LOADING
      if (loading && list.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        );
      }

      // EMPTY
      if (!loading && list.isEmpty) {
        return Center(
          child: Text(
            emptyMessage,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        );
      }

      // LIST
      return RefreshIndicator(
        color: AppColors.brand,
        onRefresh: () async {
          await Get.find<FollowersFollowingController>(
            tag: controllerTag,
          ).refreshList();
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),

          itemCount: list.length,

          separatorBuilder: (_, _) {
            return const Divider(height: 1, color: AppColors.divider);
          },

          itemBuilder: (context, index) {
            return UserListTile(user: list[index]);
          },
        ),
      );
    });
  }
}
