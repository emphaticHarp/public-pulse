import 'package:supabase_flutter/supabase_flutter.dart';
import '../../model/profile_model.dart';
import 'profile_repository.dart';

/// Handles all Supabase operations specific to viewing another user's profile.
class UserProfileRepository {
  UserProfileRepository._();
  static final UserProfileRepository instance = UserProfileRepository._();

  final _db = Supabase.instance.client.from('profiles');
  final _follows = Supabase.instance.client.from('user_follows');
  final _auth = Supabase.instance.client.auth;

  String get _uid => _auth.currentUser!.id;

  /// Delegates URL resolution to the shared ProfileRepository cache.
  String resolveUrl(String path, {required String bucket}) =>
      ProfileRepository.instance.resolveUrl(path, bucket: bucket);

  /// Fetches a public profile by [userId], including DB-computed follow counts.
  Future<ProfileModel> getUserProfile(String userId) async {
    final data = await _db
        .select(
          'user_id, username, display_name, bio, avatar_path, cover_path,'
          ' created_at, updated_at, follower_count, following_count',
        )
        .eq('user_id', userId)
        .single();
    return ProfileModel.fromJson(data);
  }

  /// Returns `true` when the current user follows [targetUserId].
  Future<bool> isFollowing(String targetUserId) async {
    final data = await _follows
        .select('follower_profile_id')
        .eq('follower_profile_id', _uid)
        .eq('following_profile_id', targetUserId)
        .maybeSingle();
    return data != null;
  }

  /// Follows [targetUserId] by inserting a row into user_follows.
  Future<void> followUser(String targetUserId) => _follows.insert({
    'follower_profile_id': _uid,
    'following_profile_id': targetUserId,
  });

  /// Unfollows [targetUserId] by deleting the matching row from user_follows.
  Future<void> unfollowUser(String targetUserId) => _follows
      .delete()
      .eq('follower_profile_id', _uid)
      .eq('following_profile_id', targetUserId);
}
