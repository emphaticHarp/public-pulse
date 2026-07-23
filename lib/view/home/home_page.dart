import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/view/notification/notification_page.dart';
import 'package:public_pulse/core/wrappers/network_wrapper.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/widget/local/app_search_bar.dart';
import 'package:public_pulse/view/post/post_card.dart';
import 'package:public_pulse/controller/notification_controller.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController controller = Get.find<HomeController>();

  final NotificationController notificationController =
      Get.find<NotificationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NetworkWrapper(
        child: Obx(
          () => CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(child: _buildHeader(context)),

              // Search Bar
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SearchBarWidget(),
                ),
              ),

              // Posts
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final post = controller.posts[index];

                    return PostCard(
                      profileImage: post.profileImage,
                      username: post.username,
                      location: post.location,
                      isCarousel: post.isCarousel,
                      imageUrl: post.imageUrl,
                      imageUrls: post.imageUrls,
                      postId: post.isCarousel ? post.id : null,
                      likeIcon: post.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      likeIconColor: post.isLiked
                          ? AppColors.loginAccentRed
                          : AppColors.gray900,
                      likeCount: post.likeCount,
                      commentCount: post.commentCount,
                      shareCount: post.shareCount,
                      caption: post.caption,
                      captionCommentCount: post.captionCommentCount,
                      onLikeTap: () {
                        post.isLiked = !post.isLiked;
                        controller.posts.refresh();
                      },
                    );
                  }, childCount: controller.posts.length),
                ),
              ),
            ],
          ),
        ),
      ),

      // in this area the bottom nav will import but it is controlling from main page so it is removed if not then 2 navigation bar are showing
    );
  }

  // ---------------- Header with logo ----------------
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Transform.scale(
                    scale: 3.5,
                    child: Image.asset(
                      'assets/images/logo.webp',
                      width: 42,
                      height: 42,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.loginAccentRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          GestureDetector(
            onTap: () {
              Get.to(() => NotificationPage());
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 28,
                  color: AppColors.gray900,
                ),
                Obx(() {
                  final count = notificationController.newNotifications.length;

                  if (count == 0) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.loginAccentRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
