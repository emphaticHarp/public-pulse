import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/controller/comment_controller.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/controller/profile_controller.dart';
import 'package:public_pulse/core/repository/post_repository.dart';
import 'package:public_pulse/model/post_model.dart';
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

  @override
  void onInit() {
    super.onInit();
    isLiked = post.isLiked.obs;
    likeCount = post.likeCount.obs;
    isSaved = post.isSaved.obs;
  }

  // Toggle like with optimistic UI, syncing to HomeController feed if active.
  Future<void> toggleLike() async {
    final wasLiked = isLiked.value;
    isLiked.value = !wasLiked;
    likeCount.value += wasLiked ? 0 : 1;

    // Sync in-memory PostModel so the profile grid reflects the change.
    post.isLiked = isLiked.value;
    post.likeCount = likeCount.value;

    // Propagate to home feed list if available.
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      final idx = home.posts.indexWhere((p) => p.id == post.id);
      if (idx != -1) {
        home.posts[idx].isLiked = isLiked.value;
        home.posts[idx].likeCount = likeCount.value;
        home.posts.refresh();
      }
    }

    final success = await _repo.toggleLike(
      postId: post.id,
      currentlyLiked: wasLiked,
    );

    if (!success) {
      // Rollback on failure.
      isLiked.value = wasLiked;
      likeCount.value += wasLiked ? 1 : 0;
      post.isLiked = wasLiked;
      post.likeCount = likeCount.value;
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

    await commentController.loadComments(post.id);

    Get.bottomSheet(
      CommentSheet(postId: post.id),
      isScrollControlled: true,
      backgroundColor: Colors.white,
    );
  }
}
