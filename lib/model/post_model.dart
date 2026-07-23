class PostModel {
  final String id;

  // User
  final String profileImage;
  final String username;
  final String location;

  // Media
  final bool isCarousel;
  final String? imageUrl;
  final List<String>? imageUrls;

  // Interaction
  final String likeCount;
  final String commentCount;
  final String shareCount;

  // Caption
  final String caption;
  final String captionCommentCount;

   bool isLiked;

  // Constructor
  PostModel({
    required this.id,

    required this.profileImage,
    required this.username,
    required this.location,

    required this.isCarousel,
    this.imageUrl,
    this.imageUrls,

    required this.likeCount,
    required this.commentCount,
    required this.shareCount,

    required this.caption,
    required this.captionCommentCount,

    this.isLiked = false,

   
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],

      profileImage: json['profile_image'],
      username: json['username'],
      location: json['location'],
      isCarousel: json['is_carousel'],

      imageUrl: json['image_url'],
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : null,

      likeCount: json['like_count'],
      commentCount: json['comment_count'],
      shareCount: json['share_count'],

      caption: json['caption'],
      captionCommentCount: json['caption_comment_count'],
    );
  }
}
