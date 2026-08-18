import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_font.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/controller/notification_controller.dart';
import 'package:public_pulse/model/notification_model.dart';

class NotificationPage extends StatelessWidget {
  NotificationPage({super.key});

  final NotificationController controller = Get.find<NotificationController>();

  static const List<String> _tabs = ['All', 'Likes', 'Comments', 'Follows'];

  //https://github.com/emphaticHarp/public-pulse-final.git

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Obx(() => _buildTabs()),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                // Loading
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.loginAccentRed),
                  );
                }

                // Error
                if (controller.errorMessage.isNotEmpty) {
                  return _buildStateMessage(
                    icon: Icons.error_outline_rounded,
                    title: "Something went wrong",
                    subtitle: controller.errorMessage.value,
                  );
                }

                // Empty
                if (controller.hasNoNotifications) {
                  return _buildStateMessage(
                    icon: Icons.notifications_none_rounded,
                    title: "No notifications yet",
                    subtitle: "You'll see likes, comments and follows here.",
                  );
                }

                // Normal notification list
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (controller.newNotifications.isNotEmpty) ...[
                          _buildSection("New", controller.newNotifications),
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
                );
              }),
            ),
          ],
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
            onTap: () => Get.back(),
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
                      child: Text(
                        _tabs[index],
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // AVATAR
          // ======================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: item.avatarUrl.isEmpty
                ? Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.gray100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: AppColors.gray400),
                  )
                : Image.network(
                    item.avatarUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.gray100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.gray400,
                          size: 28,
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(width: 12),

          // ======================================================
          // TEXT
          // ======================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.notificationText.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.1,
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
               if (item.notificationType.trim().toUpperCase() == 'POST_COMMENT' &&
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

                // ------------------------------------------------
                // FOLLOW BACK
                // ------------------------------------------------
              if (item.notificationType.trim().toUpperCase() == 'FOLLOW') ...[
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: () {
                        controller.followBack(item.actorProfileId);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.loginAccentRed,
                        side: const BorderSide(color: AppColors.loginAccentRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text(
                        'Follow Back',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ======================================================
          // POST IMAGE
          // ======================================================
          if (item.postImageUrl != null && item.postImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.postImageUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.broken_image,
                      color: AppColors.gray400,
                      size: 24,
                    ),
                  );
                },
              ),
            )
          else
            const SizedBox(width: 56),
        ],
      ),
    );
  }

 
}
