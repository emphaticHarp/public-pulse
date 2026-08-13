import 'package:supabase_flutter/supabase_flutter.dart';

class PostModel {
  final String id;

  // Profile
  final String profileId;
  final String authorUserId;
  final String username;
  final String displayName;
  final String? profileImage;

  // Post
  final String? caption;
  final String? location;

  //visibility (private and public)

  final String visibility;
  final bool isPrivateAccount;
  final bool isOwner;
  bool isUploading;

  /// Local temporary media path used while uploading.
  final List<String> localMediaPaths;

  /// True when uploading failed.
  bool uploadFailed;

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
    this.authorUserId = '',
    required this.username,
    required this.displayName,

    // Optional fields
    this.profileImage,
    this.caption,
    this.location,

    //required for visibility constructor
    required this.visibility,
    required this.isPrivateAccount,
    required this.isOwner,

    //for uploading
    this.isUploading = false,
    this.localMediaPaths = const [],
    this.uploadFailed = false,

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


  

  factory PostModel.fromJson(
    Map<String, dynamic> json,
    String? currentProfileId,
  ) {
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'])
        : <String, dynamic>{};

    final media = (json['media'] is List)
        ? List<Map<String, dynamic>>.from(
            (json['media'] as List).map((e) => Map<String, dynamic>.from(e)),
          )
        : <Map<String, dynamic>>[];

    final liked = (json['my_like'] is List)
        ? (json['my_like'] as List).isNotEmpty
        : false;

    final saved = (json['my_save'] is List)
        ? (json['my_save'] as List).isNotEmpty
        : false;
    return PostModel(
      id: json['id'],
      profileId: json['profile_id'],
      authorUserId: profile['user_id']?.toString() ?? '',
      username: profile['username'] ?? '',
      displayName: profile['display_name'] ?? '',
      profileImage: profile['avatar_path'],

      storagePaths: media
          .map((item) => item['storage_path']?.toString() ?? '')
          .where((path) => path.isNotEmpty)
          .toList(),

      mediaUrls: media
          .map((item) {
            final path = item['storage_path']?.toString();

            if (path == null || path.isEmpty) {
              return '';
            }

            return Supabase.instance.client.storage
                .from('posts-images')
                .getPublicUrl(path);
          })
          .where((url) => url.isNotEmpty)
          .toList(),

      thumbnailUrls: const [],

      isCarousel: media.length > 1,

      caption: json['caption'],
      location: json['location_name'],

      visibility: json['visibility'],
      isPrivateAccount: profile['is_private'] as bool? ?? false,
      isOwner: currentProfileId == json['profile_id'],

      isUploading: false,

      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      shareCount: json['share_count'] as int? ?? 0,
      saveCount: json['save_count'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? 0,

      isLiked: liked,
      isSaved: saved,

      createdAt: DateTime.parse(json['created_at']),
    );
  }
  //Convert PostModel to and from JSON so it can be stored and retrieved from Hive cache.

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'username': username,
      'author_user_id': authorUserId,
      'display_name': displayName,
      'profile_image': profileImage,
      'caption': caption,
      'location': location,
      'visibility': visibility,
      'is_private_account': isPrivateAccount,
      'is_owner': isOwner,
      'storage_paths': storagePaths,
      'media_urls': mediaUrls,
      'thumbnail_urls': thumbnailUrls,
      'is_carousel': isCarousel,

      'is_uploading': isUploading,
      'local_media_paths': localMediaPaths,
      'upload_failed': uploadFailed,

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
      isOwner: json['is_owner'] ?? false,
      authorUserId: json['author_user_id']?.toString() ?? '',
      storagePaths: List<String>.from(json['storage_paths'] ?? const []),
      mediaUrls: List<String>.from(json['media_urls'] ?? const []),
      thumbnailUrls: List<String>.from(json['thumbnail_urls'] ?? const []),
      isCarousel: json['is_carousel'],

      localMediaPaths: List<String>.from(json['local_media_paths'] ?? []),
      isUploading: json['is_uploading'] ?? false,
      uploadFailed: json['upload_failed'] ?? false,

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
