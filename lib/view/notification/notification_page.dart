import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_font.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/controller/notification_controller.dart';
import 'package:public_pulse/model/notification_model.dart';
import 'package:public_pulse/view/main/main_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NotificationPage extends StatelessWidget {
  NotificationPage({super.key});

  final NotificationController controller = Get.find<NotificationController>();

  static const double _contentMaxWidth = 600;

  static const List<String> _tabs = ['All', 'Likes', 'Comments', 'Follows'];

  //https://github.com/emphaticHarp/public-pulse-final.git

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Obx(() => _buildTabs()),
                const SizedBox(height: 16),
                Expanded(
                  child: Obx(() {
                    // ============================================================
                    // LOADING
                    // ============================================================

                    if (controller.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.loginAccentRed,
                        ),
                      );
                    }

                    // ============================================================
                    // ERROR
                    // Still allow swipe-down refresh
                    // ============================================================

                    if (controller.errorMessage.isNotEmpty) {
                      return RefreshIndicator(
                        color: AppColors.loginAccentRed,
                        onRefresh: controller.refreshNotifications,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.55,
                              child: _buildStateMessage(
                                icon: Icons.error_outline_rounded,
                                title: "Something went wrong",
                                subtitle: controller.errorMessage.value,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // ============================================================
                    // EMPTY
                    // Still allow swipe-down refresh
                    // ============================================================

                    if (controller.hasNoNotifications) {
                      return RefreshIndicator(
                        color: AppColors.loginAccentRed,
                        onRefresh: controller.refreshNotifications,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.55,
                              child: _buildStateMessage(
                                icon: Icons.notifications_none_rounded,
                                title: "No notifications yet",
                                subtitle:
                                    "You'll see likes, comments and follows here.",
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // ============================================================
                    // NOTIFICATION LIST + PULL TO REFRESH
                    // ============================================================

                    return RefreshIndicator(
                      color: AppColors.loginAccentRed,
                      onRefresh: controller.refreshNotifications,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (controller.newNotifications.isNotEmpty) ...[
                                _buildSection(
                                  "New",
                                  controller.newNotifications,
                                ),
                                const SizedBox(height: 32),
                              ],

                              if (controller.earlierNotifications.isNotEmpty)
                                _buildSection(
                                  "Earlier",
                                  controller.earlierNotifications,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding + 25, 24, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final didPop = await Navigator.of(context).maybePop();

              // If NotificationPage is being shown as a main/tab page
              // there may be no previous route to pop.
              if (!didPop) {
                Get.offAll(() => MainPage());
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: AppColors.gray900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Notifications',
            style: AppTextStyles.pageHeading.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Tabs ----------------
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), // px-4
      child: Container(
        height: 48, // h-12
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.gray100),
          borderRadius: BorderRadius.circular(12), // rounded-xl
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowBlack5,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final bool isActive = controller.tabIndex.value == index;
            return Expanded(
              child: InkWell(
                onTap: () {
                  controller.tabIndex.value = index;
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _tabs[index],
                            maxLines: 1,
                            style:
                                (isActive
                                        ? AppTextStyles.tabLabelActive
                                        : AppTextStyles.tabLabel)
                                    .copyWith(
                                      color: isActive
                                          ? AppColors.loginAccentRed
                                          : AppColors.textSecondary,
                                    ),
                          ),
                        ),
                      ),
                    ),
                    if (isActive)
                      Positioned(
                        bottom: -1,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.loginAccentRed,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(3),
                              topRight: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ---------------- State message (loading / error / empty) ----------------
  Widget _buildStateMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: AppColors.gray400),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.sectionHeading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.notificationTime.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Section (New / Earlier) ----------------
  Widget _buildSection(String title, List<NotificationModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16), // mb-4
          child: Text(
            title,
            style: AppTextStyles.sectionHeading.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16), // px-4
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12), // rounded-xl
            border: Border.all(color: AppColors.gray100),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowBlack5,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(items.length, (index) {
              final bool isLast = index == items.length - 1;
              return _buildNotificationTile(items[index], isLast: isLast);
            }),
          ),
        ),
      ],
    );
  }

  // ---------------- Notification tile ----------------
  Widget _buildNotificationTile(
    NotificationModel item, {
    required bool isLast,
  }) {
    final bool isCompact = MediaQuery.sizeOf(Get.context!).width < 360;
    final double avatarSize = isCompact ? 44 : 56;
    final double postImageSize = isCompact ? 44 : 56;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? 12 : 16,
        horizontal: isCompact ? 8 : 16,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ======================================================
          // AVATAR
          // ======================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(avatarSize / 2),
            child: item.avatarUrl.isEmpty
                ? Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: const BoxDecoration(
                      color: AppColors.gray100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppColors.gray400,
                      size: isCompact ? 22 : 28,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: item.avatarUrl,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                    placeholder: (_, _) {
                      return Container(
                        width: avatarSize,
                        height: avatarSize,
                        color: AppColors.gray100,
                      );
                    },
                    errorWidget: (_, _, _) {
                      return Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: const BoxDecoration(
                          color: AppColors.gray100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: AppColors.gray400,
                          size: isCompact ? 22 : 28,
                        ),
                      );
                    },
                  ),
          ),

          SizedBox(width: isCompact ? 8 : 12),

          // ======================================================
          // TEXT
          // ======================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.notificationText.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: item.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' ${item.action}'),
                    ],
                  ),
                ),

                // ------------------------------------------------
                // COMMENT TEXT
                // ------------------------------------------------
                if (item.notificationType.trim().toUpperCase() ==
                        'POST_COMMENT' &&
                    item.commentText != null &&
                    item.commentText!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.commentText!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.notificationTime.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: 5),

                Text(
                  item.timeAgo,
                  style: AppTextStyles.notificationTime.copyWith(
                    color: AppColors.slate400,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // POST IMAGE
          // ======================================================
          if (item.postImageUrl != null && item.postImageUrl!.isNotEmpty) ...[
            SizedBox(width: isCompact ? 6 : 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.postImageUrl!,
                width: postImageSize,
                height: postImageSize,
                fit: BoxFit.cover,
                placeholder: (_, _) {
                  return Container(
                    width: postImageSize,
                    height: postImageSize,
                    color: AppColors.gray100,
                  );
                },
                errorWidget: (_, _, _) {
                  return Container(
                    width: postImageSize,
                    height: postImageSize,
                    color: AppColors.gray100,
                    child: Icon(
                      Icons.broken_image,
                      color: AppColors.gray400,
                      size: isCompact ? 20 : 24,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
