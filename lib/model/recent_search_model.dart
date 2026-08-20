class RecentSearchModel {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarPath;

  const RecentSearchModel({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarPath,
  });

  factory RecentSearchModel.fromJson(Map<String, dynamic> json) {
    return RecentSearchModel(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarPath: json['avatar_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'display_name': displayName,
      'avatar_path': avatarPath,
    };
  }
}
