import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/followers_following_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_font.dart';
import '../../model/profile_model.dart';
import '../../widget/profile/user_list_tile.dart';

/// Followers / Following – client-side paginated page.
class FollowersFollowingPage extends StatelessWidget {
  final int initialTab;

  const FollowersFollowingPage({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FollowersFollowingController>();

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
            // ── Followers tab
            _UserList(
              isLoading: controller.isLoadingFollowers,
              pagedUsers: () => controller.pagedFollowers,
              totalCount: () => controller.followers.length,
              hasNext: () => controller.hasNextFollowers,
              hasPrev: () => controller.hasPrevFollowers,
              currentPage: controller.currentFollowersPage,
              onNext: () => controller.nextPage(isFollowers: true),
              onPrev: () => controller.prevPage(isFollowers: true),
              emptyMessage: 'No followers yet',
            ),
            // ── Following tab
            _UserList(
              isLoading: controller.isLoadingFollowing,
              pagedUsers: () => controller.pagedFollowing,
              totalCount: () => controller.following.length,
              hasNext: () => controller.hasNextFollowing,
              hasPrev: () => controller.hasPrevFollowing,
              currentPage: controller.currentFollowingPage,
              onNext: () => controller.nextPage(isFollowers: false),
              onPrev: () => controller.prevPage(isFollowers: false),
              emptyMessage: 'Not following anyone yet',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab bar
class _FFTabBar extends StatelessWidget implements PreferredSizeWidget {
  final ValueChanged<int> onTabChanged;

  const _FFTabBar({required this.onTabChanged});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) => TabBar(
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

// ── Per-tab list with Prev / Next pagination bar
//
// `currentPage` is the RxInt the controller mutates on next/prev; reading
// its `.value` inside Obx (via the getters below) is what makes this list
// rebuild when the page changes.

class _UserList extends StatelessWidget {
  final RxBool isLoading;
  final List<FollowerModel> Function() pagedUsers;
  final int Function() totalCount;
  final bool Function() hasNext;
  final bool Function() hasPrev;
  final RxInt currentPage;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final String emptyMessage;

  const _UserList({
    required this.isLoading,
    required this.pagedUsers,
    required this.totalCount,
    required this.hasNext,
    required this.hasPrev,
    required this.currentPage,
    required this.onNext,
    required this.onPrev,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) => Obx(() {
    final loading = isLoading.value;
    // ignore: unused_local_variable
    final page = currentPage.value; // subscribes Obx to page changes
    final total = totalCount();
    final list = pagedUsers();

    // ── Full-page loader (first page not yet loaded)
    if (loading && total == 0) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }

    // ── Empty state
    if (!loading && total == 0) {
      return Center(
        child: Text(
          emptyMessage,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    // ── List + pagination bar
    return Column(
      children: [
        // User list — not scrollable beyond the current page.
        Expanded(
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, i) => UserListTile(user: list[i]),
          ),
        ),

        // Inline page-turn progress indicator (shown while (re)loading).
        if (loading)
          const LinearProgressIndicator(
            color: AppColors.brand,
            backgroundColor: AppColors.divider,
            minHeight: 2,
          ),

        // Prev / Next navigation bar.
        _PaginationBar(
          hasPrev: hasPrev(),
          hasNext: hasNext(),
          loading: loading,
          onPrev: onPrev,
          onNext: onNext,
        ),
      ],
    );
  });
}

// ── Pagination bar widget

class _PaginationBar extends StatelessWidget {
  final bool hasPrev;
  final bool hasNext;
  final bool loading;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _PaginationBar({
    required this.hasPrev,
    required this.hasNext,
    required this.loading,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    // Hide the bar entirely when there is only one page (no prev and no next).
    if (!hasPrev && !hasNext) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 246, 241, 239),
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Previous button
          _NavButton(
            label: '← Previous',
            enabled: hasPrev && !loading,
            onTap: onPrev,
          ),

          // ── Next button
          _NavButton(
            label: 'Next →',
            enabled: hasNext && !loading,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: enabled ? onTap : null,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand,
        disabledForegroundColor: const Color(0x6664748B),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: enabled
                ? const Color(0x99E6192E)
                : AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: enabled ? AppColors.brand : const Color(0x6664748B),
        ),
      ),
    );
  }
}