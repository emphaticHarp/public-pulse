import 'package:flutter/material.dart';
import 'package:public_pulse/widget/post/post_header.dart';
import 'package:public_pulse/widget/post/post_media.dart';
import 'package:public_pulse/widget/post/interaction_bar.dart';
import 'package:public_pulse/widget/post/post_caption.dart';

class PostCard extends StatelessWidget {
  final String profileImage; //post header import
  final String username; //post header import
  final String location; //post header import

  final bool isCarousel; //post media import
  final String? imageUrl; //post media import
  final List<String>? imageUrls; //post media import
  final String? postId; //post media import

  final IconData likeIcon; //interaction bar import
  final Color likeIconColor; //interaction bar import

  final String likeCount; //interaction bar import
  final String commentCount; //interaction bar import
  final String shareCount; //interaction bar import
  final VoidCallback? onLikeTap; //interaction bar import

  final String caption; //post caption import
  final String captionCommentCount; //post caption import

  const PostCard({
    super.key,
    required this.profileImage,
    required this.username,
    required this.location,

    required this.isCarousel,
    this.imageUrl,
    this.imageUrls,
    this.postId,

    required this.likeIcon,
    required this.likeIconColor,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    this.onLikeTap,

    required this.caption,
    required this.captionCommentCount,
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
            location: location,
          ),
          if (isCarousel)
            PostCarouselMedia(
              imageUrls: imageUrls!,
              postId: postId!,
            )
          else
            PostMedia(imageUrl: imageUrl!),

          InteractionBar(
            likeIcon: likeIcon,
            likeIconColor: likeIconColor,
            likeCount: likeCount,
            commentCount: commentCount,
            shareCount: shareCount,
            onLikeTap: onLikeTap,
          ),

          PostCaption(
            username: username,
            caption: caption,
            commentCount: captionCommentCount,
          ),
        ],
      ),
    );
  }
}
