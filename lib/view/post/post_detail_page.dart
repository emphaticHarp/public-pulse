import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/controller/post_detail_controller.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:public_pulse/model/post_model.dart';
import 'package:public_pulse/widget/post/interaction_bar.dart';
import 'package:public_pulse/widget/post/post_caption.dart';
import 'package:public_pulse/widget/post/post_header.dart';
import 'package:public_pulse/widget/post/post_media.dart';
import 'package:tiktok_double_tap_like/tiktok_double_tap_like.dart';

/// Full-screen detail view for a single post.
/// Receives the already-loaded [PostModel] — zero extra Supabase requests.
class PostDetailPage extends StatelessWidget {
  final PostModel post;

  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // Put controller scoped to this post; auto-deleted when page is popped.
    final ctrl = Get.put(
      PostDetailController(post),
      tag: post.id,
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header: avatar, username, location, options menu
            PostHeader(
              profileImage: post.profileImage ?? '',
              username: post.username,
              authorId: post.profileId,
              authorUserId: post.authorUserId,
              location: post.location,
              postId: post.id,
              isOwner: post.isOwner,
            ),

            const SizedBox(height: 12),

            // Post media: single image or carousel
            _PostMedia(
              post: post,
              controller: ctrl,
            ),

            // Reactive action bar (like, comment, share, save)
            Obx(
              () => InteractionBar(
                likeIcon: ctrl.isLiked.value
                    ? Icons.favorite
                    : Icons.favorite_border,
                likeIconColor: ctrl.isLiked.value
                    ? AppColors.loginAccentRed
                    : AppColors.gray900,
                likeCount: ctrl.likeCount.value.toString(),
                commentCount: post.commentCount.toString(),
                shareCount: post.shareCount.toString(),
                isBookmarked: ctrl.isSaved.value,
                onLikeTap: ctrl.toggleLike,
                onCommentTap: ctrl.openComments,
                onBookmarkTap: ctrl.toggleSave,
              ),
            ),

            // Caption and timestamp
            if ((post.caption ?? '').isNotEmpty) ...[
            PostCaption(
              username: post.username,
              caption: post.caption!,
            ),
              const SizedBox(height: 6),
            ],

            _Timestamp(date: post.createdAt),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: AppColors.surfaceDefault,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: () {
            // Delete the scoped controller before popping.
            Get.delete<PostDetailController>(tag: post.id, force: true);
            Get.back();
          },
        ),
        title: const Text(
          'Post',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      );
}

// ─────────────────────────────────────────────
// POST MEDIA
// ─────────────────────────────────────────────

class _PostMedia extends StatelessWidget {
  final PostModel post;
  final PostDetailController controller;

  const _PostMedia({
    required this.post,
    required this.controller,
  });

  double get _aspectRatio {
    if (post.mediaAspectRatios.isEmpty) {
      return 4 / 5;
    }

    final ratio = post.mediaAspectRatios.first;

    if (!ratio.isFinite || ratio <= 0) {
      return 4 / 5;
    }

    return ratio;
  }

  @override
  Widget build(BuildContext context) {
    if (post.mediaUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final Widget media;

    if (post.isCarousel) {
      media = PostCarouselMedia(
        imageUrls: post.mediaUrls,
        aspectRatios: post.mediaAspectRatios,
        postId: post.id,
      );
    } else {
      media = PostMedia(
        imageUrl: post.mediaUrls.first,
        aspectRatio: _aspectRatio,
      );
    }

    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: DoubleTapLikeWidget(
        onLike: (_) {
          if (!controller.isLiked.value) {
            controller.toggleLike();
          }
        },
        likeWidget: const Icon(
          Icons.favorite_rounded,
          color: AppColors.loginAccentRed,
          size: 100,
        ),
        likeWidth: 110,
        likeHeight: 110,
        child: media,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TIMESTAMP
// ─────────────────────────────────────────────

class _Timestamp extends StatelessWidget {
  final DateTime date;

  const _Timestamp({required this.date});

  String _format(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        _format(date),
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.gray500,
        ),
      ),
    );
  }
}
