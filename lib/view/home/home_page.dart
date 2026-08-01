import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/core/wrappers/network_wrapper.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/widget/local/app_search_bar.dart';
import 'package:public_pulse/view/post/post_card.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController controller = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[DEBUG-UI] HomePage.build: called, posts.length=${controller.posts.length}',
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: NetworkWrapper(
        child: Obx(() {
          return RefreshIndicator(
          onRefresh: controller.refreshFeed,
            color: AppColors.loginAccentRed,

            child: CustomScrollView(
              controller: controller.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(child: _buildHeader(context)),

                // Search Bar (always visible)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: SearchBarWidget(),
                  ),
                ),

                

                Obx(() {
                  return SliverToBoxAdapter(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: controller.newPostCount.value == 0
                          ? const SizedBox.shrink()
                          : Padding(
                              key: const ValueKey("new_posts_banner"),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: GestureDetector(
                                onTap: () async {
                                  await controller.refreshFeed();

                                  if (controller.scrollController.hasClients) {
                                    controller.scrollController.animateTo(
                                      0,
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.loginAccentRed,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: Text(
                                      controller.newPostCount.value == 1
                                          ? "1 New Post"
                                          : "${controller.newPostCount.value} New Posts",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  );
                }),

                // Loading state
                if (controller.isLoading.value)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.loginAccentRed,
                      ),
                    ),
                  )
                // Empty state
                else if (controller.posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 18),
                          Text(
                            "No Posts Yet",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Posts from everyone will appear here.",
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                // Posts loaded
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= controller.posts.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.loginAccentRed,
                                ),
                              ),
                            );
                          }

                          final post = controller.posts[index];

                          return PostCard(
                            key: ValueKey(post.id),
                            profileImage: post.profileImage ?? '',
                            username: post.username,
                            location: post.location ?? '',

                            isCarousel: post.isCarousel,

                            imageUrl: post.mediaUrls.isNotEmpty
                                ? post.mediaUrls.first
                                : null,
                            imageUrls: post.mediaUrls,

                            postId: post.isCarousel ? post.id : null,
                            likeIcon: post.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            likeIconColor: post.isLiked
                                ? AppColors.loginAccentRed
                                : AppColors.gray900,

                            likeCount: post.likeCount.toString(),
                            commentCount: post.commentCount.toString(),
                            shareCount: post.shareCount.toString(),
                            caption: post.caption ?? '',
                            captionCommentCount: post.commentCount.toString(),
                            onLikeTap: () {
                              post.isLiked = !post.isLiked;
                              controller.posts.refresh();
                            },
                          );
                        },
                        childCount:
                            controller.posts.length +
                            (controller.isLoadingMore.value ? 1 : 0),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ---------------- Header with logo ----------------
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
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
    );
  }
}
