import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../core/repository/comment_repository.dart';
import '../model/comment_model.dart';
import 'package:public_pulse/controller/home_controller.dart';

import 'package:public_pulse/core/cache/cache_manager.dart';

class CommentController extends GetxController {
  final CommentRepository _repository = CommentRepository();

  final RxList<CommentModel> comments = <CommentModel>[].obs;

  final isLoading = false.obs;

  final isSubmitting = false.obs;
  final Uuid _uuid = const Uuid();
  Map<String, dynamic>? _currentProfile;

  final TextEditingController commentController = TextEditingController();

  String? currentPostId;

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  Future<void> _loadCurrentProfile() async {
    if (_currentProfile != null) return;

    _currentProfile = await _repository.getCurrentProfile();
  }

  Future<void> loadComments(String postId) async {
    currentPostId = postId;

    await _loadCurrentProfile();

    // Load cache first
    final cachedComments = CacheManager.getCachedComments(postId);

    if (cachedComments.isNotEmpty) {
      comments.assignAll(cachedComments);
    }

    try {
      isLoading.value = comments.isEmpty;

      // Only fetch comment count
      final serverCount = await _repository.getCommentCount(postId);

      // Cache is already correct
      if (serverCount == comments.length) {
        isLoading.value = false;
        return;
      }

      // Something changed -> fetch latest comments
      final serverComments = await _repository.getComments(postId);

      comments.assignAll(serverComments);

      await CacheManager.cacheComments(postId, serverComments);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addComment() async {
    if (isSubmitting.value) return;

    final text = commentController.text.trim();

    if (text.isEmpty) return;

    if (text.length > 500) {
      Get.snackbar("Too long", "Maximum 500 characters");
      return;
    }

    isSubmitting.value = true;

    if (currentPostId == null) return;

    await _loadCurrentProfile();

    if (_currentProfile == null) return;

    final tempId = _uuid.v4();

    final tempComment = CommentModel(
      id: tempId,
      postId: currentPostId!,
      profileId: _currentProfile!['id'],
      username: _currentProfile!['username'],
      profileImage: _currentProfile!['avatar_path'],
      content: text,
      createdAt: DateTime.now(),
      isPending: true,
    );

    comments.insert(0, tempComment);

    final home = Get.find<HomeController>();

    final postIndex = home.posts.indexWhere((e) => e.id == currentPostId);

    if (postIndex != -1) {
      home.posts[postIndex].commentCount++;
      home.posts.refresh();
    }

    commentController.clear();

    /// ---------- BACKGROUND UPLOAD ----------
    try {
      final uploadedComment = await _repository.addComment(
        postId: currentPostId!,
        content: text,
      );

      if (uploadedComment != null) {
        final index = comments.indexWhere((e) => e.id == tempId);

        if (index != -1) {
          comments[index] = uploadedComment;

          await CacheManager.cacheComments(currentPostId!, comments);
        }

        await home.refreshSinglePost(currentPostId!);
      } else {
        comments.removeWhere((e) => e.id == tempId);

        await CacheManager.cacheComments(currentPostId!, comments);

        if (postIndex != -1) {
          home.posts[postIndex].commentCount--;
          home.posts.refresh();
        }

        Get.snackbar("Error", "Failed to send comment");
      }
    } finally {
      isSubmitting.value = false;
    }
  }
}
