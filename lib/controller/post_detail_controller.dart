import 'package:get/get.dart';
import 'package:public_pulse/controller/comment_controller.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/controller/profile_controller.dart';
import 'package:public_pulse/core/repository/post_repository.dart';
import 'package:public_pulse/model/post_model.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/view/comment/comment_sheet.dart';

/// Minimal reactive state for the Post Detail page.
/// Handles like/save optimistic UI and delegates to existing repository logic.
class PostDetailController extends GetxController {
  PostDetailController(this.post);

  final PostModel post;
  final _repo = PostRepository();

  late final RxBool isLiked;
  late final RxInt likeCount;
  late final RxBool isSaved;

  final RxBool isLikeProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Use Home feed state when the same post exists there.
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();

      final index = home.posts.indexWhere((p) => p.id == post.id);

      if (index != -1) {
        post.isLiked = home.posts[index].isLiked;
        post.likeCount = home.posts[index].likeCount;
        post.isSaved = home.posts[index].isSaved;
      }
    }

    isLiked = post.isLiked.obs;
    likeCount = post.likeCount.obs;
    isSaved = post.isSaved.obs;
  }

  Future<void> toggleLike() async {
    if (isLikeProcessing.value) {
      return;
    }

    isLikeProcessing.value = true;

    try {
      // ============================================================
      // USE HOME CONTROLLER'S WORKING LIKE LOGIC
      // ============================================================

      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();

        final index = home.posts.indexWhere((p) => p.id == post.id);

        if (index != -1) {
          final homePost = home.posts[index];

          // Update Home optimistically immediately.
          final oldLiked = homePost.isLiked;
          final oldCount = homePost.likeCount;

          homePost.isLiked = !oldLiked;
          homePost.likeCount = homePost.isLiked
              ? oldCount + 1
              : oldCount > 0
              ? oldCount - 1
              : 0;

          home.posts.refresh();

          // Update Detail UI immediately.
          post.isLiked = homePost.isLiked;
          post.likeCount = homePost.likeCount;

          isLiked.value = homePost.isLiked;
          likeCount.value = homePost.likeCount;

          // Sync to Supabase in background.
          Future.microtask(() async {
            final success = await _repo.toggleLike(
              postId: post.id,
              currentlyLiked: oldLiked,
            );

            if (!success) {
              // Roll back only if DB update fails.
              homePost.isLiked = oldLiked;
              homePost.likeCount = oldCount;

              post.isLiked = oldLiked;
              post.likeCount = oldCount;

              isLiked.value = oldLiked;
              likeCount.value = oldCount;

              home.posts.refresh();
            }

            isLikeProcessing.value = false;
          });

          return;
        }
      }

      // ============================================================
      // FALLBACK WHEN POST IS NOT IN HOME FEED
      // ============================================================

      final oldLiked = post.isLiked;
      final oldCount = post.likeCount;

      post.isLiked = !oldLiked;

      if (post.isLiked) {
        post.likeCount++;
      } else {
        post.likeCount = post.likeCount > 0 ? post.likeCount - 1 : 0;
      }

      isLiked.value = post.isLiked;
      likeCount.value = post.likeCount;

      final success = await _repo.toggleLike(
        postId: post.id,
        currentlyLiked: oldLiked,
      );

      if (!success) {
        post.isLiked = oldLiked;
        post.likeCount = oldCount;

        isLiked.value = oldLiked;
        likeCount.value = oldCount;
      }
    } catch (e) {
    } finally {
      isLikeProcessing.value = false;
    }
  }

  // Toggle save with optimistic UI, keeping the Profile saved list in sync.
  Future<void> toggleSave() async {
    final wasSaved = isSaved.value;
    isSaved.value = !wasSaved;
    post.isSaved = isSaved.value;

    // Sync profile saved list if the profile controller is active.
    if (Get.isRegistered<ProfileController>()) {
      await ProfileController.to.onPostSaveChanged(post, saved: isSaved.value);
    }

    final success = await _repo.toggleSave(
      postId: post.id,
      currentlySaved: wasSaved,
    );

    if (!success) {
      isSaved.value = wasSaved;
      post.isSaved = wasSaved;
      if (Get.isRegistered<ProfileController>()) {
        await ProfileController.to.onPostSaveChanged(post, saved: wasSaved);
      }
    }
  }

  // Open the existing comment bottom sheet.
  Future<void> openComments() async {
    CommentController commentController;

    if (Get.isRegistered<CommentController>()) {
      commentController = Get.find<CommentController>();
    } else {
      commentController = Get.put(CommentController());
    }

    commentController.prepareComments(post.id);

    Get.bottomSheet(
      CommentSheet(postId: post.id),
      isScrollControlled: true,
      backgroundColor: AppColors.transparentFull,
      barrierColor: AppColors.overlayBlack50,
      isDismissible: true,
      enableDrag: true,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
      exitBottomSheetDuration: const Duration(milliseconds: 220),
    );

    Future.microtask(
      () => commentController.loadComments(post.id),
    );
  }
}
