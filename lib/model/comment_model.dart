import 'package:flutter/foundation.dart';

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

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      profileId: map['profile_id'] as String,

      username: map['username'] ?? map['profiles']?['username'] ?? '',

      profileImage: map['profile_image'] ?? map['profiles']?['avatar_path'],

      content: map['content'] ?? '',

      createdAt: DateTime.parse(map['created_at']),

      isPending: map['is_pending'] ?? false,
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
