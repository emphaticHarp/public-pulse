import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/repository/comment_repository.dart';
import '../model/comment_model.dart';
import 'package:public_pulse/controller/home_controller.dart';
import 'package:public_pulse/core/cache/cache_manager.dart';
import 'package:public_pulse/widget/local/app_alert.dart';

class CommentController extends GetxController {
  final CommentRepository _repository = CommentRepository();

  final RxList<CommentModel> comments = <CommentModel>[].obs;

  final isLoading = false.obs;

  final isSubmitting = false.obs;
  final Uuid _uuid = const Uuid();
  Map<String, dynamic>? _currentProfile;

  final TextEditingController commentController = TextEditingController();

  String? currentPostId;

  String? get currentProfileId => _currentProfile?['id'];

  final RxnString editingCommentId = RxnString();

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  String _resolveAvatarUrl(String? value) {
    final avatar = value?.trim() ?? '';

    if (avatar.isEmpty) {
      return '';
    }

    // Google avatar / already complete URL.
    if (avatar.startsWith('http://') ||
        avatar.startsWith('https://')) {
      return avatar;
    }

    // User uploaded/updated avatar in Supabase.
    return Supabase.instance.client.storage
        .from('avatars')
        .getPublicUrl(avatar);
  }

  Future<void> _loadCurrentProfile() async {
    if (_currentProfile != null) return;

    _currentProfile = await _repository.getCurrentProfile();
  }

  void prepareComments(String postId) {
    currentPostId = postId;

    final cachedComments = CacheManager.getCachedComments(postId);

    if (cachedComments.isNotEmpty) {
      comments.assignAll(cachedComments);
      isLoading.value = false;
    } else {
      comments.clear();
      isLoading.value = true;
    }
  }

  Future<void> loadComments(String postId) async {
    currentPostId = postId;

    // ─────────────────────────────────────────────
    // CACHE FIRST — no network wait
    // ─────────────────────────────────────────────

    final cachedComments = CacheManager.getCachedComments(postId);

    if (cachedComments.isNotEmpty) {
      comments.assignAll(cachedComments);
      isLoading.value = false;
    } else {
      comments.clear();
      isLoading.value = true;
    }

    try {
      // Profile + comment count can load together.
      final results = await Future.wait([
        _loadCurrentProfile(),
        _repository.getCommentCount(postId),
      ]);

      final serverCount = results[1] as int;

      // Cached comments are still current.
      if (serverCount == comments.length) {
        return;
      }

      // Only download full comments when something changed.
      final serverComments = await _repository.getComments(postId);

      comments.assignAll(serverComments);

      await CacheManager.cacheComments(postId, serverComments);
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addComment() async {
    if (isSubmitting.value) return;

    final text = commentController.text.trim();

    if (text.isEmpty) return;

    if (text.length > 500) {
      CustomAlert.show(
        title: 'Too long',
        message: 'Maximum 500 characters',
        icon: Icons.warning_amber_rounded,
        color: AppColors.semanticOrange,
      );
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
      profileImage: _resolveAvatarUrl(
        _currentProfile!['avatar_path']?.toString(),
      ),
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

        CustomAlert.show(
          title: 'Error',
          message: 'Failed to send comment',
          icon: Icons.error_outline,
          color: AppColors.loginAccentRed,
        );
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  void startEditing(CommentModel comment) {
    editingCommentId.value = comment.id;
    commentController.text = comment.content;
    commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: commentController.text.length),
    );
  }

  void cancelEditing() {
    editingCommentId.value = null;
    commentController.clear();
  }

  Future<void> submitComment() async {
    if (editingCommentId.value != null) {
      await _updateComment(editingCommentId.value!, commentController.text);
    } else {
      await addComment();
    }
  }

  Future<void> editComment(String commentId, String newText) async {
    await _updateComment(commentId, newText);
  }

  Future<void> _updateComment(String commentId, String content) async {
    if (isSubmitting.value) return;

    final text = content.trim();
    if (text.isEmpty) return;

    if (text.length > 500) {
      CustomAlert.show(
        title: 'Too long',
        message: 'Maximum 500 characters',
        icon: Icons.warning_amber_rounded,
        color: AppColors.semanticOrange,
      );
      return;
    }

    final index = comments.indexWhere((e) => e.id == commentId);
    if (index == -1) {
      cancelEditing();
      return;
    }

    final original = comments[index];

    isSubmitting.value = true;

    comments[index] = original.copyWith(content: text);
    commentController.clear();
    editingCommentId.value = null;

    try {
      final updated = await _repository.updateComment(
        commentId: commentId,
        content: text,
      );

      final i = comments.indexWhere((e) => e.id == commentId);

      if (updated != null) {
        if (i != -1) {
          comments[i] = updated;
          await CacheManager.cacheComments(currentPostId!, comments);
        }
      } else {
        if (i != -1) comments[i] = original;
        CustomAlert.show(
          title: 'Error',
          message: 'Failed to update comment',
          icon: Icons.error_outline,
          color: AppColors.loginAccentRed,
        );
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteComment(String commentId) async {
    final index = comments.indexWhere((e) => e.id == commentId);
    if (index == -1) return;

    final removed = comments[index];

    comments.removeAt(index);

    if (currentPostId != null) {
      await CacheManager.cacheComments(currentPostId!, comments);
    }

    final home = Get.find<HomeController>();
    final postIndex = home.posts.indexWhere((e) => e.id == currentPostId);
    if (postIndex != -1) {
      home.posts[postIndex].commentCount--;
      home.posts.refresh();
    }

    final success = await _repository.deleteComment(commentId);

    if (!success) {
      comments.insert(index, removed);
      if (currentPostId != null) {
        await CacheManager.cacheComments(currentPostId!, comments);
      }
      if (postIndex != -1) {
        home.posts[postIndex].commentCount++;
        home.posts.refresh();
      }
      CustomAlert.show(
        title: 'Error',
        message: 'Failed to delete comment',
        icon: Icons.error_outline,
        color: AppColors.loginAccentRed,
      );
    }
  }
}
