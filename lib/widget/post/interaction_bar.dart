import 'package:flutter/material.dart';

class InteractionBar extends StatefulWidget {
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
  State<InteractionBar> createState() => _InteractionBarState();
}

class _InteractionBarState extends State<InteractionBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _likeAnimationController;
  late final Animation<double> _likeScaleAnimation;

  @override
  void initState() {
    super.initState();

    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _likeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.30,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.30,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_likeAnimationController);
  }

  void _handleLikeTap() {
    _likeAnimationController.forward(from: 0);

    widget.onLikeTap?.call();
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

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
              // =================================================
              // LIKE
              // =================================================

              GestureDetector(
                onTap: _handleLikeTap,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: _likeScaleAnimation,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Icon(
                          widget.likeIcon,
                          key: ValueKey(
                            '${widget.likeIcon}-${widget.likeIconColor}',
                          ),
                          size: 26,
                          color: widget.likeIconColor,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      widget.likeCount,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // =================================================
              // COMMENT
              // =================================================
              GestureDetector(
                onTap: widget.onCommentTap,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 26),
                    const SizedBox(width: 6),
                    Text(
                      widget.commentCount,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // const SizedBox(width: 24),

              // =================================================
              // SHARE
              // =================================================
              // GestureDetector(
              //   onTap: widget.onShareTap,
              //   behavior: HitTestBehavior.opaque,
              //   child: Row(
              //     children: [
              //       const Icon(Icons.send_outlined, size: 26),
              //       const SizedBox(width: 6),
              //       Text(
              //         widget.shareCount,
              //         style: const TextStyle(
              //           fontSize: 14,
              //           fontWeight: FontWeight.w600,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),

          // =====================================================
          // BOOKMARK
          // =====================================================
          if (widget.showBookmark)
            GestureDetector(
              onTap: widget.onBookmarkTap,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                size: 28,
              ),
            ),
        ],
      ),
    );
  }
}
