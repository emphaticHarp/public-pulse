import 'dart:io';

import 'package:flutter/material.dart';
import 'package:public_pulse/widget/post/post_header.dart';
import 'package:public_pulse/widget/post/post_media.dart';
import 'package:public_pulse/widget/post/interaction_bar.dart';
import 'package:public_pulse/widget/post/post_caption.dart';

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

  final String postId;

  final IconData likeIcon;
  final Color likeIconColor;

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

    required this.postId,

    required this.likeIcon,
    required this.likeIconColor,

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostHeader(
            profileImage: profileImage,
            username: username,
            authorId: authorId,
            authorUserId: authorUserId,
            location: location,
            postId: postId,
            isOwner: isOwner,
          ),

          // =====================================================
          // MEDIA
          // =====================================================
          if (isUploading)
            _UploadingMedia(
              localMediaPaths: localMediaPaths,
              isCarousel: isCarousel,
            )
          else if (uploadFailed)
            _UploadFailedMedia(
              localMediaPaths: localMediaPaths,
              isCarousel: isCarousel,
            )
          else if (isCarousel)
            PostCarouselMedia(imageUrls: imageUrls ?? const [], postId: postId)
          else if (imageUrl != null)
            PostMedia(imageUrl: imageUrl!)
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
// UPLOADING MEDIA
// ===============================================================

class _UploadingMedia extends StatelessWidget {
  final List<String> localMediaPaths;
  final bool isCarousel;

  const _UploadingMedia({
    required this.localMediaPaths,
    required this.isCarousel,
  });

  @override
  Widget build(BuildContext context) {
    if (localMediaPaths.isEmpty) {
      return _mediaPlaceholder(child: const CircularProgressIndicator());
    }

    Widget media;

    if (isCarousel && localMediaPaths.length > 1) {
      media = SizedBox(
        height: 350,
        width: double.infinity,
        child: PageView.builder(
          itemCount: localMediaPaths.length,
          itemBuilder: (context, index) {
            return _safeImage(localMediaPaths[index]);
          },
        ),
      );
    } else {
      media = _safeImage(localMediaPaths.first);
    }

    return Stack(
      children: [
        media,

        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.45),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 35,
                    height: 35,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Uploading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _safeImage(String path) {
    final file = File(path);

    if (!file.existsSync()) {
      return _mediaPlaceholder(
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 50,
          color: Colors.grey,
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 350,
    );
  }

  Widget _mediaPlaceholder({required Widget child}) {
    return Container(
      height: 350,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Center(child: child),
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
        color: Colors.grey.shade200,
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
          color: Colors.grey.shade200,
        );
      }
    }

    return Stack(
      children: [
        media,

        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.55),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, color: Colors.white, size: 42),
                  SizedBox(height: 10),
                  Text(
                    'Upload failed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Please try again',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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
