import 'package:flutter/material.dart';

class InteractionBar extends StatelessWidget {
  final IconData likeIcon;
  final Color likeIconColor;
  final String likeCount;
  final String commentCount;
  final String shareCount;

  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;

  final bool showBookmark;
  final bool isBookmarked;
  final VoidCallback? onBookmarkTap;

  const InteractionBar({
    super.key,
    required this.likeIcon,
    required this.likeIconColor,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    this.onLikeTap,
    this.onCommentTap,
    this.onShareTap,
    this.showBookmark = true,
    this.isBookmarked = false,
    this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              // Like button
              GestureDetector(
                onTap: onLikeTap,
                child: Row(
                  children: [
                    Icon(likeIcon, size: 26, color: likeIconColor),
                    const SizedBox(width: 6),
                    Text(
                      likeCount,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Comment button
              GestureDetector(
                onTap: onCommentTap,
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 26),
                    const SizedBox(width: 6),
                    Text(
                      commentCount,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Share button
              GestureDetector(
                onTap: onShareTap,
                child: Row(
                  children: [
                    Transform.rotate(
                      angle: 0,
                      child: const Icon(Icons.send_outlined, size: 26),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      shareCount,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (showBookmark)
            GestureDetector(
              onTap: onBookmarkTap,
              child: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                size: 28,
              ),
            ),
        ],
      ),
    );
  }
}