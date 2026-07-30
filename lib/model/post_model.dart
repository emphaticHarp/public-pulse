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
  final List<String> storagePaths;
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
    required this.storagePaths,
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

      // Store the original Supabase storage paths for each media file.
      storagePaths: media
          .map((item) => item['storage_path'] as String)
          .toList(),

      // Convert storage paths into public image and video URLs.
      mediaUrls: media.map((item) {
        final path = item['storage_path'] as String;
        final mediaType = item['media_type'] as String;

        final bucket = mediaType == 'VIDEO' ? 'posts-videos' : 'posts-images';

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

  //Convert PostModel to and from JSON so it can be stored and retrieved from Hive cache.

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'username': username,
      'display_name': displayName,
      'profile_image': profileImage,
      'caption': caption,
      'location': location,
      'visibility': visibility,
      'is_private_account': isPrivateAccount,
      'storage_paths': storagePaths,
      'media_urls': mediaUrls,
      'thumbnail_urls': thumbnailUrls,
      'is_carousel': isCarousel,
      'is_video': isVideo,
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'save_count': saveCount,
      'view_count': viewCount,
      'is_liked': isLiked,
      'is_saved': isSaved,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PostModel.fromCache(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      profileId: json['profile_id'],
      username: json['username'],
      displayName: json['display_name'],
      profileImage: json['profile_image'],
      caption: json['caption'],
      location: json['location'],
      visibility: json['visibility'],
      isPrivateAccount: json['is_private_account'],
      storagePaths: List<String>.from(json['storage_paths'] ?? []),
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
      thumbnailUrls: List<String>.from(json['thumbnail_urls'] ?? []),
      isCarousel: json['is_carousel'],
      isVideo: json['is_video'],
      likeCount: json['like_count'],
      commentCount: json['comment_count'],
      shareCount: json['share_count'],
      saveCount: json['save_count'],
      viewCount: json['view_count'],
      isLiked: json['is_liked'] ?? false,
      isSaved: json['is_saved'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
