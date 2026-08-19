import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/core/wrappers/network_wrapper.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/view/post/post_card.dart';
import 'package:public_pulse/controller/comment_controller.dart';
import 'package:public_pulse/view/comment/comment_sheet.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController controller = Get.find<HomeController>();

  static const double _feedMaxWidth = 600;

  @override
  Widget build(BuildContext context) {
    debugPrint("🏠 HomePage Build");
    return Scaffold(
      backgroundColor: AppColors.white,
   body: SafeArea(
  bottom: false,
  child: NetworkWrapper(
    child: RefreshIndicator(
          onRefresh: controller.refreshFeed,
          color: AppColors.loginAccentRed,
          child: CustomScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header (static - no Obx needed)
              SliverToBoxAdapter(child: _buildHeader(context)),

              // New Posts Banner (reactive - wrapped in Obx)
              Obx(() {
                return SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: controller.newPostCount.value == 0
                        ? const SizedBox.shrink()
                        : Center(
                            key: const ValueKey("new_posts_banner"),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: _feedMaxWidth,
                              ),
                              child: Padding(
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
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
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
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                );
              }),

              // Loading / Empty / Posts (reactive - wrapped in Obx)
              Obx(() {
                // Loading state
                if (controller.isLoading.value) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.loginAccentRed,
                      ),
                    ),
                  );
                }

                // Empty state
                if (controller.posts.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 420,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 72,
                                color: AppColors.greyShade400,
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                "No Posts Yet",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Posts from everyone will appear here.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Posts loaded
                return SliverPadding(
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

                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _feedMaxWidth,
                            ),
                            child: PostCard(
                              key: ValueKey(post.id),
                              profileImage: post.profileImage ?? '',
                              username: post.username,
                              authorId: post.profileId,
                              authorUserId: post.authorUserId,
                              location: post.location ?? '',
                              isCarousel: post.isCarousel,
                              isOwner: post.isOwner,
                              imageUrl: post.mediaUrls.isNotEmpty
                                  ? post.mediaUrls.first
                                  : null,
                              imageUrls: post.mediaUrls,
                              mediaAspectRatios: post.mediaAspectRatios,
                              postId: post.id,

                              isUploading: post.isUploading,
                              localMediaPaths: post.localMediaPaths,

                              likeIcon: post.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              likeIconColor: post.isLiked
                                  ? AppColors.loginAccentRed
                                  : AppColors.gray900,
                              isLiked: post.isLiked,
                              likeCount: post.likeCount.toString(),
                              commentCount: post.commentCount.toString(),
                              shareCount: post.shareCount.toString(),
                              caption: post.caption ?? '',
                              //for save post
                              isBookmarked: post.isSaved,
                              onBookmarkTap: () {
                                controller.toggleSave(post);
                              },
                              // for like
                              // Like
                              onLikeTap: () {
                                controller.toggleLike(post);
                              },
                              // for opeming the comment tile
                              // Comment
                              onCommentTap: () {
                                CommentController commentController;

                                if (Get.isRegistered<CommentController>()) {
                                  commentController = Get.find<CommentController>();
                                } else {
                                  commentController = Get.put(CommentController());
                                }

                                // 1. Immediately prepare cached comments.
                                commentController.prepareComments(post.id);

                                // 2. Open the sheet immediately with slide-up animation.
                                Get.bottomSheet(
                                  CommentSheet(postId: post.id),
                                  isScrollControlled: true,
                                  backgroundColor: AppColors.transparentFull,
                                  barrierColor: AppColors.overlayBlack50,
                                  isDismissible: true,
                                  enableDrag: true,
                                  enterBottomSheetDuration: const Duration(
                                    milliseconds: 280,
                                  ),
                                  exitBottomSheetDuration: const Duration(
                                    milliseconds: 220,
                                  ),
                                );

                                // 3. Refresh from Supabase AFTER the sheet starts opening.
                                Future.microtask(
                                  () => commentController.loadComments(post.id),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      childCount:
                          controller.posts.length +
                          (controller.isLoadingMore.value ? 1 : 0),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ),
  );
  }

  // ---------------- Header with logo ----------------
  Widget _buildHeader(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _feedMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 132,
              height: 52,
              child: Image.asset(
                'assets/images/logo.webp',
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                errorBuilder: (context, error, stackTrace) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.loginAccentRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
