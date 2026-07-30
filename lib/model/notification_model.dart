// ## Table `notifications`

// ### Columns

// | Name | Type | Constraints |
// |------|------|-------------|
// | `id` | `uuid` | Primary |
// | `recipient_profile_id` | `uuid` |  |
// | `actor_profile_id` | `uuid` |  |
// | `notification_type` | `notification_type` |  |
// | `post_id` | `uuid` |  Nullable |
// | `comment_id` | `uuid` |  Nullable |
// | `is_read` | `bool` |  |
// | `created_at` | `timestamptz` |  |

import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationModel {
  final String id;

  final String recipientProfileId;
  final String actorProfileId;

  final String notificationType;

  final String? postId;
  final String? commentId;

  final bool isRead;
  final DateTime createdAt;

  // UI fields
  final String avatarUrl;
  final String name;
  final String action;
  final String timeAgo;
  final String? postImageUrl;

  NotificationModel({
    required this.id,
    required this.recipientProfileId,
    required this.actorProfileId,
    required this.notificationType,
    this.postId,
    this.commentId,
    required this.isRead,
    required this.createdAt,

    required this.avatarUrl,
    required this.name,
    required this.action,
    required this.timeAgo,
    this.postImageUrl,
  });

  /// Converts a notification row from Supabase into a NotificationModel for the UI.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] ?? {};
    final post = json['post'] ?? {};
    final media = (post['media'] as List?) ?? [];

    String? postImageUrl;

    if (media.isNotEmpty) {
      final firstMedia = media.first;
      final String storagePath = firstMedia['storage_path'];
      final String mediaType = firstMedia['media_type'];

      final bucket = mediaType == 'VIDEO' ? 'posts-videos' : 'posts-images';

      postImageUrl = Supabase.instance.client.storage
          .from(bucket)
          .getPublicUrl(storagePath);
    }

    final String? avatarPath = actor['avatar_path'];

    final avatarUrl = avatarPath == null
        ? ''
        : Supabase.instance.client.storage
              .from('profile-images')
              .getPublicUrl(avatarPath);

    return NotificationModel(
      id: json['id'],
      recipientProfileId: json['recipient_profile_id'],
      actorProfileId: json['actor_profile_id'],
      notificationType: json['notification_type'],
      postId: json['post_id'],
      commentId: json['comment_id'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),

      avatarUrl: avatarUrl,

      name: actor['display_name'] ?? actor['username'] ?? 'Unknown',

      action: _notificationText(json['notification_type']),

      timeAgo: _timeAgo(DateTime.parse(json['created_at'])),

      postImageUrl: postImageUrl,
    );
  }

  /// Converts notification type into user-friendly text.
  static String _notificationText(String type) {
    switch (type) {
      case 'LIKE':
        return 'liked your post';
      case 'COMMENT':
        return 'commented on your post';
      case 'FOLLOW':
        return 'started following you';
      case 'MENTION':
        return 'mentioned you';
      default:
        return 'interacted with you';
    }
  }

  /// Converts DateTime into "2m", "3h", "Yesterday", etc.
  static String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
