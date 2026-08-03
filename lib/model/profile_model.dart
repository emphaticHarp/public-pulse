/// Tabs shown on the Profile Screen.
enum ProfileTab { photos, videos, saved }

/// Represents a single row in the followers or following list.
class FollowerModel {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarPath;

  const FollowerModel({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarPath,
  });

  factory FollowerModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? json;
    return FollowerModel(
      userId: (profile['user_id'] ?? json['user_id'] ?? '') as String,
      username: (profile['username'] ?? '') as String,
      displayName: profile['display_name'] as String?,
      avatarPath: profile['avatar_path'] as String?,
    );
  }
}

class ProfileModel {
  final String id;
  final String username;
  final String? displayName;
  final String? bio;
  final String? avatarPath;
  final String? coverPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    required this.username,
    this.displayName,
    this.bio,
    this.avatarPath,
    this.coverPath,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final profile = ProfileModel(
      id: json['user_id'] as String,
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      avatarPath: json['avatar_path'] as String?,
      coverPath: json['cover_path'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
    return profile;
  }

  static DateTime? _parseDate(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;

  Map<String, dynamic> toJson() => {
    'user_id': id,
    'username': username,
    'display_name': displayName,
    'bio': bio,
    'avatar_path': avatarPath,
    'cover_path': coverPath,
  };

  ProfileModel copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? avatarPath,
    String? coverPath,
    DateTime? updatedAt,
  }) => ProfileModel(
    id: id,
    username: username ?? this.username,
    displayName: displayName ?? this.displayName,
    bio: bio ?? this.bio,
    avatarPath: avatarPath ?? this.avatarPath,
    coverPath: coverPath ?? this.coverPath,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileModel &&
          id == other.id &&
          username == other.username &&
          displayName == other.displayName &&
          bio == other.bio &&
          avatarPath == other.avatarPath &&
          coverPath == other.coverPath &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt);
  
  /// Override hashCode to ensure that two ProfileModel instances with the same value
  @override
  int get hashCode => Object.hash(
    id,
    username,
    displayName,
    bio,
    avatarPath,
    coverPath,
    createdAt,
    updatedAt,
  );
}
