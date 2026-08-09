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

  String get _uid => _auth.currentUser!.id;

  // ─────────────────────────────────────────────
  // PROFILE
  // ─────────────────────────────────────────────

  /// Gets the internal profile.id from auth user_id.
  Future<String> _getProfileIdFromUserId(String userId) async {
    final data = await _db.select('id').eq('user_id', userId).single();

    return data['id'] as String;
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

    // Already following?
    final alreadyFollowing = await isFollowing(targetUserId);

    if (alreadyFollowing) {
      return;
    }

    // Add target to my following list.
    await _addToChunk(
      profileId: myProfileId,
      column: 'following_profile_ids',
      targetProfileId: targetProfileId,
    );

    // Add me to target's followers list.
    await _addToChunk(
      profileId: targetProfileId,
      column: 'follower_profile_ids',
      targetProfileId: myProfileId,
    );
  }

  // ─────────────────────────────────────────────
  // UNFOLLOW
  // ─────────────────────────────────────────────

  /// Removes a follow relationship from the chunked system.
  Future<void> unfollowUser(String targetUserId) async {
    final myProfileId = await _getProfileIdFromUserId(_uid);

    final targetProfileId = await _getProfileIdFromUserId(targetUserId);

    // Remove target from my following list.
    await _removeFromChunks(
      profileId: myProfileId,
      column: 'following_profile_ids',
      targetProfileId: targetProfileId,
    );

    // Remove me from target's followers list.
    await _removeFromChunks(
      profileId: targetProfileId,
      column: 'follower_profile_ids',
      targetProfileId: myProfileId,
    );
  }

  // ─────────────────────────────────────────────
  // ADD TO CHUNK
  // ─────────────────────────────────────────────

  Future<void> _addToChunk({
    required String profileId,
    required String column,
    required String targetProfileId,
  }) async {
    final rows = await _followChunks
        .select('id, profile_id, chunk, $column')
        .eq('profile_id', profileId)
        .order('chunk', ascending: true);

    // Check if already exists anywhere.
    for (final row in rows) {
      final ids = row[column];

      if (ids is List && ids.any((id) => id?.toString() == targetProfileId)) {
        return;
      }
    }

    // Try to add to an existing chunk.
    for (final row in rows) {
      final ids = List<String>.from(
        (row[column] as List?)?.map((e) => e.toString()) ?? [],
      );

      // Keep the chunk reasonably sized.
      if (ids.length < 100) {
        ids.add(targetProfileId);

        await _followChunks.update({column: ids}).eq('id', row['id']);

        return;
      }
    }

    // No suitable chunk exists.
    //
    // Create the first/next chunk.
    final nextChunk = rows.isEmpty
        ? 1
        : ((rows.last['chunk'] as num?)?.toInt() ?? 0) + 1;

    await _followChunks.insert({
      'profile_id': profileId,
      'chunk': nextChunk,
      column: [targetProfileId],
    });
  }

  // ─────────────────────────────────────────────
  // REMOVE FROM CHUNKS
  // ─────────────────────────────────────────────

  Future<void> _removeFromChunks({
    required String profileId,
    required String column,
    required String targetProfileId,
  }) async {
    final rows = await _followChunks
        .select('id, profile_id, chunk, $column')
        .eq('profile_id', profileId)
        .order('chunk', ascending: true);

    for (final row in rows) {
      final ids = List<String>.from(
        (row[column] as List?)?.map((e) => e.toString()) ?? [],
      );

      if (!ids.contains(targetProfileId)) {
        continue;
      }

      ids.remove(targetProfileId);

      if (ids.isEmpty) {
        // Delete empty chunk.
        await _followChunks.delete().eq('id', row['id']);
      } else {
        // Update existing chunk.
        await _followChunks.update({column: ids}).eq('id', row['id']);
      }

      return;
    }
  }
}
