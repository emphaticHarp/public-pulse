/// Tabs shown on the Profile Screen.
enum ProfileTab { photos, saved }

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
    final userId = (profile['user_id'] ?? json['user_id'] ?? '') as String;
    final username = (profile['username'] ?? '') as String;
    final displayName = profile['display_name'] as String?;
    final avatarPath = profile['avatar_path'] as String?;

    // Debug logging
    assert(() {
      print('[FF_MODEL] fromJson - input json keys: ${json.keys.toList()}');
      print(
        '[FF_MODEL] fromJson - profiles key exists: ${json.containsKey("profiles")}',
      );
      print('[FF_MODEL] fromJson - profile: $profile');
      print(
        '[FF_MODEL] fromJson - parsed: userId=$userId, username=$username, displayName=$displayName, avatarPath=$avatarPath',
      );
      return true;
    }());

    return FollowerModel(
      userId: userId,
      username: username,
      displayName: displayName,
      avatarPath: avatarPath,
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
  // DB-computed counters — populated when the query includes these columns.
  final int? followerCount;
  final int? followingCount;
  final int? postCount;
  final String? accountStatus;
  final String? referCode;

  const ProfileModel({
    required this.id,
    required this.username,
    this.displayName,
    this.bio,
    this.avatarPath,
    this.coverPath,
    this.createdAt,
    this.updatedAt,
    this.followerCount,
    this.followingCount,
    this.postCount,
    this.accountStatus,
    this.referCode,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['user_id'] as String,
    username: json['username'] as String? ?? '',
    displayName: json['display_name'] as String?,
    bio: json['bio'] as String?,
    avatarPath: json['avatar_path'] as String?,
    coverPath: json['cover_path'] as String?,
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
    followerCount: (json['follower_count'] as num?)?.toInt(),
    followingCount: (json['following_count'] as num?)?.toInt(),
    postCount: (json['post_count'] as num?)?.toInt(),
    accountStatus: json['account_status']?.toString(),
    referCode: json['refer_code']?.toString(),
  );

  static DateTime? _parseDate(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;

  Map<String, dynamic> toJson() => {
    'user_id': id,
    'username': username,
    'display_name': displayName,
    'bio': bio,
    'avatar_path': avatarPath,
    'cover_path': coverPath,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'follower_count': followerCount,
    'following_count': followingCount,
    'post_count': postCount,
    'account_status': accountStatus,
    'refer_code': referCode,
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
    followerCount: followerCount,
    followingCount: followingCount,
    postCount: postCount,
    accountStatus: accountStatus,
    referCode: referCode,
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
          updatedAt == other.updatedAt &&
          postCount == other.postCount &&
          followerCount == other.followerCount &&
          followingCount == other.followingCount &&
          accountStatus == other.accountStatus &&
          referCode == other.referCode);

  /// Override hashCode to ensure that two ProfileModel instances with the same values are equal.
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
    followerCount,
    followingCount,
    postCount,
    accountStatus,
    referCode,
  );
}
