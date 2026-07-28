/// Tabs shown on the Profile Screen. Kept alongside the model 
/// controller and UI can depend on it without an extra file.
enum ProfileTab { photos, videos, saved }

class ProfileModel {
  final String userId;
  final String username;
  final String? displayName;
  final String? bio;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;
  final bool profileCompleted;
  final bool isVerified;
  final int postsCount;
  final int followersCount;
  final int followingCount;

  const ProfileModel({
    required this.userId,
    required this.username,
    this.displayName,
    this.bio,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    this.profileCompleted = false,
    this.isVerified = false,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) => ProfileModel(
        userId: map['user_id'] as String,
        username: map['username'] as String? ?? '',
        displayName: map['display_name'] as String?,
        bio: map['bio'] as String?,
        profilePhotoUrl: map['profile_photo_url'] as String?,//---------------avatar path-----------------
        coverPhotoUrl: map['cover_photo_url'] as String?,//-------------cover path-------------------
        // profileCompleted: map['profile_completed'] as bool? ?? false,
        // isVerified: map['is_verified'] as bool? ?? false,
        postsCount: map['posts_count'] as int? ?? 0,
        followersCount: map['followers_count'] as int? ?? 0,
        followingCount: map['following_count'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'username': username,
        'display_name': displayName,
        'bio': bio,
        'profile_photo_url': profilePhotoUrl,
        'cover_photo_url': coverPhotoUrl,
        'profile_completed': profileCompleted,
      };

  ProfileModel copyWith({
    String? username,
    String? bio,
    String? profilePhotoUrl,
    String? coverPhotoUrl,
    bool? profileCompleted,
  }) =>
      ProfileModel(
        userId: userId,
        username: username ?? this.username,
        displayName: displayName,
        bio: bio ?? this.bio,
        profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
        coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
        profileCompleted: profileCompleted ?? this.profileCompleted,
        isVerified: isVerified,
        postsCount: postsCount,
        followersCount: followersCount,
        followingCount: followingCount,
      );
}