import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:public_pulse/model/profile_model.dart';
import 'profile_repository.dart';

/// Handles Supabase operations for viewing another user's public profile.
///
/// Follow relationships use the same chunked system as the
/// Followers/Following page:
///
/// user_follow2_chunked
/// ├── follower_profile_ids
/// └── following_profile_ids
class UserProfileRepository {
  UserProfileRepository._();

  static final UserProfileRepository instance = UserProfileRepository._();

  final _db = Supabase.instance.client.from('profiles');

  final _followChunks = Supabase.instance.client.from('user_follow2_chunked');

  final _auth = Supabase.instance.client.auth;

  /// Cache profile-id lookups.
  ///
  /// Key   = profiles.user_id / auth user ID
  /// Value = Future of profiles.id
  ///
  /// Using Future here also prevents duplicate requests when
  /// multiple methods ask for the same profile ID simultaneously.
  final Map<String, Future<String>> _profileIdCache = {};

  String get _uid => _auth.currentUser!.id;

  // ─────────────────────────────────────────────
  // PROFILE
  // ─────────────────────────────────────────────

  /// Gets the internal profile.id from auth user_id.
  Future<String> _getProfileIdFromUserId(String userId) {
    return _profileIdCache.putIfAbsent(userId, () async {
      try {
        final data = await _db.select('id').eq('user_id', userId).single();

        final profileId = data['id'] as String;

        debugPrint(
          '[USER_PROFILE_REPO] Profile ID fetched: '
          '$userId -> $profileId',
        );

        return profileId;
      } catch (e) {
        // Do not permanently cache a failed request.
        _profileIdCache.remove(userId);

        rethrow;
      }
    });
  }

  Future<String> getProfileIdFromUserId(String userId) {
    return _getProfileIdFromUserId(userId);
  }

  /// Fetches the target user's public profile.
  Future<ProfileModel> getUserProfile(String userId) async {
    final data = await _db
        .select(
          'user_id, username, display_name, bio, avatar_path, cover_path,'
          ' created_at, updated_at, follower_count, following_count, post_count',
        )
        .eq('user_id', userId)
        .single();

    return ProfileModel.fromJson(data);
  }

  Future<List<String>> getUserPostImages(String userId) async {
    // Convert auth user_id -> internal profiles.id
    final profileId = await _getProfileIdFromUserId(userId);

    final rows = await Supabase.instance.client
        .from('posts')
        .select('''
        id,
        created_at,
        post_media(
          storage_path,
          thumbnail_path,
          media_type,
          media_order
        )
      ''')
        .eq('profile_id', profileId)
        .eq('status', 'ACTIVE')
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false);

    final urls = <String>[];

    for (final row in rows) {
      final mediaRaw = row['post_media'];

      debugPrint('[USER_POSTS] post=${row['id']} media=$mediaRaw');

      if (mediaRaw is! List || mediaRaw.isEmpty) {
        continue;
      }

      final media = mediaRaw.map((e) => Map<String, dynamic>.from(e)).toList();

      media.sort((a, b) {
        final aOrder = (a['media_order'] as num?)?.toInt() ?? 0;
        final bOrder = (b['media_order'] as num?)?.toInt() ?? 0;

        return aOrder.compareTo(bOrder);
      });

      // One thumbnail/image per post.
      for (final item in media) {
        final path = item['storage_path']?.toString();
        final type = item['media_type']?.toString().toLowerCase();

        if (path == null || path.isEmpty) {
          continue;
        }

        if (type != null && !type.contains('image')) {
          continue;
        }

        final url = Supabase.instance.client.storage
            .from('posts-images')
            .getPublicUrl(path);

        urls.add(url);

        break;
      }
    }

    return urls;
  }

  // ─────────────────────────────────────────────
  // URL
  // ─────────────────────────────────────────────

  String resolveUrl(String path, {required String bucket}) {
    return ProfileRepository.instance.resolveUrl(path, bucket: bucket);
  }

  // ─────────────────────────────────────────────
  // CHECK: ME → TARGET
  // ─────────────────────────────────────────────

  /// Returns true if the current user follows [targetUserId].
  Future<bool> isFollowing(String targetUserId) async {
    final myProfileId = await _getProfileIdFromUserId(_uid);

    final targetProfileId = await _getProfileIdFromUserId(targetUserId);

    final rows = await _followChunks
        .select('following_profile_ids')
        .eq('profile_id', myProfileId)
        .order('chunk', ascending: true);

    for (final row in rows) {
      final ids = row['following_profile_ids'];

      if (ids is List) {
        for (final id in ids) {
          if (id?.toString() == targetProfileId) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // ─────────────────────────────────────────────
  // CHECK: TARGET → ME
  // ─────────────────────────────────────────────

  /// Returns true if [targetUserId] follows the current user.
  Future<bool> isFollowedBy(String targetUserId) async {
    final myProfileId = await _getProfileIdFromUserId(_uid);

    final targetProfileId = await _getProfileIdFromUserId(targetUserId);

    final rows = await _followChunks
        .select('following_profile_ids')
        .eq('profile_id', targetProfileId)
        .order('chunk', ascending: true);

    for (final row in rows) {
      final ids = row['following_profile_ids'];

      if (ids is List) {
        for (final id in ids) {
          if (id?.toString() == myProfileId) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // ─────────────────────────────────────────────
  // FOLLOW
  // ─────────────────────────────────────────────

  /// Adds a follow relationship using the existing chunked system.
  ///
  /// Current user:
  ///   following_profile_ids → target
  ///
  /// Target user:
  ///   follower_profile_ids → current user
  Future<void> followUser(String targetUserId) async {
    final myProfileId = await _getProfileIdFromUserId(_uid);
    final targetProfileId = await _getProfileIdFromUserId(targetUserId);

    if (myProfileId == targetProfileId) {
      return;
    }

    await Supabase.instance.client.rpc(
      'follow_user',
      params: {'p_following_profile_id': targetProfileId},
    );
  }

  // ─────────────────────────────────────────────
  // UNFOLLOW
  // ─────────────────────────────────────────────

  /// Removes a follow relationship from the chunked system.
  Future<void> unfollowUser(String targetUserId) async {
    final myProfileId = await _getProfileIdFromUserId(_uid);
    final targetProfileId = await _getProfileIdFromUserId(targetUserId);

    if (myProfileId == targetProfileId) {
      return;
    }

    await Supabase.instance.client.rpc(
      'unfollow_user',
      params: {'p_following_profile_id': targetProfileId},
    );
  }
}
