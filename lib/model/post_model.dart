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
  // Counts
  int likeCount;
  int commentCount;
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

    final liked = (json['my_like'] as List?)?.isNotEmpty ?? false;

    return PostModel(
      id: json['id'],
      profileId: json['profile_id'],

      username: profile['username'] ?? '',
      displayName: profile['display_name'] ?? '',
      profileImage: profile['avatar_path'],

      storagePaths: media
          .map((item) => item['storage_path'] as String)
          .toList(),

      mediaUrls: media.map((item) {
        final path = item['storage_path'] as String;
        return Supabase.instance.client.storage
            .from('posts-images')
            .getPublicUrl(path);
      }).toList(),

      thumbnailUrls: const [],

      isCarousel: media.length > 1,

      caption: json['caption'],
      location: json['location_name'],

      visibility: json['visibility'],
      isPrivateAccount: profile['is_private'],

      likeCount: json['like_count'],
      commentCount: json['comment_count'],
      shareCount: json['share_count'],
      saveCount: json['save_count'],
      viewCount: json['view_count'],

      isLiked: liked,

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
