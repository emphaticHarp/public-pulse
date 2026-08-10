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
  final String? commentText;

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
    this.commentText,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // ==========================================================
    // ACTOR
    // ==========================================================

    final actor = json['actor'] is Map
        ? Map<String, dynamic>.from(json['actor'])
        : <String, dynamic>{};

    // ==========================================================
    // POST
    // ==========================================================

    final post = json['post'] is Map
        ? Map<String, dynamic>.from(json['post'])
        : <String, dynamic>{};

    final media = post['media'] is List
        ? List<dynamic>.from(post['media'])
        : <dynamic>[];

    String? postImageUrl;

    if (media.isNotEmpty) {
      final firstMedia = media.first;

      if (firstMedia is Map) {
        final storagePath = firstMedia['storage_path'];

        if (storagePath != null && storagePath.toString().isNotEmpty) {
          postImageUrl = Supabase.instance.client.storage
              .from('posts-images')
              .getPublicUrl(storagePath.toString());
        }
      }
    }

    // ==========================================================
    // AVATAR
    // ==========================================================

    final avatarPath = actor['avatar_path'];

    String avatarUrl = '';

    if (avatarPath != null && avatarPath.toString().isNotEmpty) {
      avatarUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(avatarPath.toString());
    }

    // ==========================================================
    // COMMENT TEXT
    // ==========================================================

    final commentText = json['comment_text']?.toString();

    // ==========================================================
    // CREATED AT
    // ==========================================================

    final createdAt = DateTime.parse(json['created_at'].toString());

    // ==========================================================
    // NAME
    // ==========================================================

    final name = (actor['display_name']?.toString().trim().isNotEmpty ?? false)
        ? actor['display_name'].toString()
        : (actor['username']?.toString() ?? 'Unknown');

    // ==========================================================
    // NOTIFICATION TYPE
    // ==========================================================

    final type = json['notification_type'].toString();

    return NotificationModel(
      id: json['id'].toString(),
      recipientProfileId: json['recipient_profile_id'].toString(),
      actorProfileId: json['actor_profile_id'].toString(),

      notificationType: type,

      postId: json['post_id']?.toString(),
      commentId: json['comment_id']?.toString(),

      isRead: json['is_read'] as bool? ?? false,

      createdAt: createdAt,

      avatarUrl: avatarUrl,

      name: name,

      action: _notificationText(type),

      timeAgo: _timeAgo(createdAt),

      postImageUrl: postImageUrl,

      commentText: commentText,
    );
  }

  // ============================================================
  // NOTIFICATION TEXT
  // ============================================================

  static String _notificationText(String type) {
    switch (type.trim().toUpperCase()) {
      case 'POST_LIKE':
        return 'liked your post';

      case 'POST_COMMENT':
        return 'commented on your post';

      case 'POST_FOLLOW':
        return 'started following you';

      case 'POST_MENTION':
        return 'mentioned you';

      default:
        return 'interacted with you';
    }
  }

  // ============================================================
  // TIME
  // ============================================================

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
