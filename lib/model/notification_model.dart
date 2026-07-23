class NotificationModel {
  final String avatarUrl;
  final String name;
  final String action;
  final String timeAgo;
  final String? postImageUrl;

  NotificationModel({
    required this.avatarUrl,
    required this.name,
    required this.action,
    required this.timeAgo,
    this.postImageUrl,
  });
}