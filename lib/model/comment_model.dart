import 'package:supabase_flutter/supabase_flutter.dart';

class CommentModel {
  final String id;

  final String postId;

  final String profileId;

  final String username;

  final String? profileImage;

  final String content;

  final DateTime createdAt;

  /// Used only for optimistic UI.
  /// true = still uploading
  final bool isPending;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.profileId,
    required this.username,
    this.profileImage,
    required this.content,
    required this.createdAt,
    this.isPending = false,
  });

  static String? resolveProfileImage(dynamic value) {
    final avatar = value?.toString().trim() ?? '';

    if (avatar.isEmpty) {
      return null;
    }

    // Google avatar or any already-complete URL.
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return avatar;
    }

    // User changed profile picture inside Public Pulse.
    // avatar_path now contains a Supabase Storage path.
    return Supabase.instance.client.storage
        .from('avatars')
        .getPublicUrl(avatar);
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? profileData;

    final rawProfile = map['profiles'];

    if (rawProfile is Map) {
      profileData = Map<String, dynamic>.from(rawProfile);
    } else if (rawProfile is List && rawProfile.isNotEmpty) {
      final first = rawProfile.first;

      if (first is Map) {
        profileData = Map<String, dynamic>.from(first);
      }
    }

    final thumbnailAvatar = profileData?['avatar_thumbnail_path']
        ?.toString()
        .trim();
    final optimisticAvatar = map['profile_image']?.toString().trim();
    final normalAvatar = profileData?['avatar_path']?.toString().trim();
    final rawAvatar = thumbnailAvatar != null && thumbnailAvatar.isNotEmpty
        ? thumbnailAvatar
        : optimisticAvatar != null && optimisticAvatar.isNotEmpty
        ? optimisticAvatar
        : normalAvatar;

    return CommentModel(
      id: map['id'].toString(),
      postId: map['post_id'].toString(),
      profileId: map['profile_id'].toString(),

      username:
          map['username']?.toString() ??
          profileData?['username']?.toString() ??
          '',

      profileImage: resolveProfileImage(rawAvatar),

      content: map['content']?.toString() ?? '',

      createdAt: DateTime.parse(map['created_at'].toString()),

      isPending: map['is_pending'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'profile_id': profileId,
      'username': username,
      'profile_image': profileImage,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_pending': isPending,
    };
  }

  CommentModel copyWith({
    String? id,
    String? postId,
    String? profileId,
    String? username,
    String? profileImage,
    String? content,
    DateTime? createdAt,
    bool? isPending,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      profileId: profileId ?? this.profileId,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isPending: isPending ?? this.isPending,
    );
  }

  @override
  String toString() {
    return 'CommentModel(id: $id, content: $content)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CommentModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
