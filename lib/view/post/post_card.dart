import 'dart:io';

import 'package:flutter/material.dart';
import 'package:public_pulse/widget/post/post_header.dart';
import 'package:public_pulse/widget/post/post_media.dart';
import 'package:public_pulse/widget/post/interaction_bar.dart';
import 'package:public_pulse/widget/post/post_caption.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:tiktok_double_tap_like/tiktok_double_tap_like.dart';

class PostCard extends StatelessWidget {
  final String profileImage;
  final String username;
  final String authorId;
  final String authorUserId;
  final String? location;

  final bool isCarousel;
  final bool isOwner;

  final String? imageUrl;
  final List<String>? imageUrls;

  // Aspect ratio for each media item.
  final List<double> mediaAspectRatios;

  final String postId;

  final IconData likeIcon;
  final Color likeIconColor;
  final bool isLiked;

  final String likeCount;
  final String commentCount;
  final String shareCount;

  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;

  final bool isBookmarked;
  final VoidCallback? onBookmarkTap;

  final bool isUploading;
  final List<String> localMediaPaths;
  final bool uploadFailed;

  final String caption;

  const PostCard({
    super.key,
    required this.profileImage,
    required this.username,
    required this.authorUserId,
    required this.authorId,
    this.location,

    required this.isCarousel,
    required this.isOwner,

    this.imageUrl,
    this.imageUrls,
    required this.mediaAspectRatios,

    required this.postId,

    required this.likeIcon,
    required this.likeIconColor,
    required this.isLiked,

    required this.likeCount,
    required this.commentCount,
    required this.shareCount,

    this.onLikeTap,
    this.onCommentTap,

    this.isBookmarked = false,
    this.onBookmarkTap,

    this.isUploading = false,
    this.localMediaPaths = const [],
    this.uploadFailed = false,

    required this.caption,
  });

  Widget _doubleTapLike({required Widget child, required double aspectRatio}) {
    final safeRatio = aspectRatio.isFinite && aspectRatio > 0
        ? aspectRatio
        : 4 / 5;

    return AspectRatio(
      aspectRatio: safeRatio,
      child: DoubleTapLikeWidget(
        onLike: (likeCount) {
          // Double tap should LIKE only.
          // Never unlike an already-liked post.
          if (!isLiked) {
            onLikeTap?.call();
          }
        },

        likeWidget: const Icon(
          Icons.favorite_rounded,
          color: AppColors.loginAccentRed,
          size: 100,
        ),

        likeWidth: 110,
        likeHeight: 110,

        child: child,
      ),
    );
  }

  String? get displayLocation {
    final value = location?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value.split(',').first.trim();
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // TEMPORARY UPLOADING POST
    // ============================================================

    if (isUploading) {
      return const _UploadingPostIndicator();
    }

    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostHeader(
            profileImage: profileImage,
            username: username,
            authorId: authorId,
            authorUserId: authorUserId,
            location: displayLocation,
            postId: postId,
            isOwner: isOwner,
          ),

          // =====================================================
          // MEDIA
          // =====================================================
          if (uploadFailed)
            _UploadFailedMedia(
              localMediaPaths: localMediaPaths,
              isCarousel: isCarousel,
            )
          else if (isCarousel)
            _doubleTapLike(
              aspectRatio: mediaAspectRatios.isNotEmpty
                  ? mediaAspectRatios.first
                  : 4 / 5,
              child: PostCarouselMedia(
                imageUrls: imageUrls ?? const [],
                aspectRatios: mediaAspectRatios,
                postId: postId,
              ),
            )
          else if (imageUrl != null)
            _doubleTapLike(
              aspectRatio: mediaAspectRatios.isNotEmpty
                  ? mediaAspectRatios.first
                  : 4 / 5,
              child: PostMedia(
                imageUrl: imageUrl!,
                aspectRatio: mediaAspectRatios.isNotEmpty
                    ? mediaAspectRatios.first
                    : 4 / 5,
              ),
            )
          else
            const SizedBox.shrink(),

          // =====================================================
          // INTERACTION
          // =====================================================
          InteractionBar(
            likeIcon: likeIcon,
            likeIconColor: likeIconColor,
            likeCount: likeCount,
            commentCount: commentCount,
            shareCount: shareCount,
            onLikeTap: onLikeTap,
            onCommentTap: onCommentTap,
            isBookmarked: isBookmarked,
            onBookmarkTap: onBookmarkTap,
          ),

          // =====================================================
          // CAPTION
          // =====================================================
          PostCaption(username: username, caption: caption),
        ],
      ),
    );
  }
}

// ===============================================================
// UPLOADING POST
// ===============================================================

class _UploadingPostIndicator extends StatelessWidget {
  const _UploadingPostIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      color: AppColors.surfaceDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your post is uploading...',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: AppColors.gray100,
              color: AppColors.loginAccentRed,
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// UPLOAD FAILED
// ===============================================================

class _UploadFailedMedia extends StatelessWidget {
  final List<String> localMediaPaths;
  final bool isCarousel;

  const _UploadFailedMedia({
    required this.localMediaPaths,
    required this.isCarousel,
  });

  @override
  Widget build(BuildContext context) {
    Widget media;

    if (localMediaPaths.isEmpty) {
      media = Container(
        height: 350,
        width: double.infinity,
        color: AppColors.greyShade200,
      );
    } else {
      final file = File(localMediaPaths.first);

      if (file.existsSync()) {
        media = Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 350,
        );
      } else {
        media = Container(
          height: 350,
          width: double.infinity,
          color: AppColors.greyShade200,
        );
      }
    }

    return Stack(
      children: [
        media,

        Positioned.fill(
          child: Container(
            color: AppColors.overlayBlack55,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, color: AppColors.white, size: 42),
                  SizedBox(height: 10),
                  Text(
                    'Upload failed',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Please try again',
                    style: TextStyle(color: AppColors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
