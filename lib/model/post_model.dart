import 'package:supabase_flutter/supabase_flutter.dart';

class PostModel {
  final String id;

  // Profile
  final String profileId;
  final String username;
  final String displayName;
  final String? profileImage;

  // Post
  final String? caption;
  final String? location;

  //visibility (private and public)

  final String visibility;
  final bool isPrivateAccount;

  // Media
  final List<String> mediaUrls;
  final List<String> thumbnailUrls;
  final bool isCarousel;
  final bool isVideo;

  // Counts
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int saveCount;
  final int viewCount;

  // User interaction
  bool isLiked;
  bool isSaved;

  // Time
  final DateTime createdAt;

  // Constructor
  PostModel({
    required this.id,
    required this.profileId,
    required this.username,
    required this.displayName,

    // Optional fields
    this.profileImage,
    this.caption,
    this.location,

    //required for visibility constructor
    required this.visibility,
    required this.isPrivateAccount,

    // Required media fields
    required this.mediaUrls,
    required this.thumbnailUrls,
    required this.isCarousel,
    required this.isVideo,

    // Required count fields
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.saveCount,
    required this.viewCount,

    // Default values
    this.isLiked = false,
    this.isSaved = false,

    // Required date
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] ?? {};

    final media = List<Map<String, dynamic>>.from(json['media'] ?? []);

    return PostModel(
      id: json['id'],
      profileId: json['profile_id'],

      username: profile['username'] ?? '',
      displayName: profile['display_name'] ?? '',
      profileImage: profile['avatar_path'],

      // Convert storage paths into public image and video URLs.
      mediaUrls: media.map((item) {
        final path = item['storage_path'] as String;
        final mediaType = item['media_type'] as String;

        final bucket = mediaType == 'VIDEO' ? 'post-videos' : 'post-images';

        return Supabase.instance.client.storage.from(bucket).getPublicUrl(path);
      }).toList(),

      thumbnailUrls: const [],

      isCarousel: media.length > 1,

      isVideo: media.any((item) => item['media_type'] == 'VIDEO'),

      caption: json['caption'],
      location: json['location_name'],

      visibility: json['visibility'],
      isPrivateAccount: profile['is_private'],

      likeCount: json['like_count'],
      commentCount: json['comment_count'],
      shareCount: json['share_count'],
      saveCount: json['save_count'],
      viewCount: json['view_count'],

      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
