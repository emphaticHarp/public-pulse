import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/core/services/current_user_service.dart';

class FollowRepository {
  FollowRepository._();

  static final FollowRepository instance = FollowRepository._();

  final _client = Supabase.instance.client;

  final _followChunks = Supabase.instance.client.from('user_follow2_chunked');

  // ============================================================
  // GET FOLLOWING IDS
  // ============================================================

  Future<Set<String>> getFollowingIds() async {
    final profileId = await CurrentUserService.instance.getProfileId();

    if (profileId == null) {
      debugPrint('[FOLLOW] Current profile ID is null');
      return {};
    }

    debugPrint('[FOLLOW] Loading following IDs for profile: $profileId');

    final rows = await _followChunks
        .select('following_profile_ids')
        .eq('profile_id', profileId);

    final ids = <String>{};

    for (final row in rows) {
      final following = row['following_profile_ids'];

      if (following is List) {
        ids.addAll(following.map((e) => e.toString()));
      }
    }

    debugPrint('[FOLLOW] Loaded ${ids.length} following IDs');

    return ids;
  }

  // ============================================================
  // FOLLOW USER
  // ============================================================

  Future<bool> followUser(String targetProfileId) async {
    try {
      final myProfileId = await CurrentUserService.instance.getProfileId();

      if (myProfileId == null) {
        debugPrint('[FOLLOW] Current profile ID is null');
        return false;
      }

      if (myProfileId == targetProfileId) {
        debugPrint('[FOLLOW] Cannot follow yourself');
        return false;
      }

      debugPrint('[FOLLOW] $myProfileId → $targetProfileId');

      // ----------------------------------------------------------
      // Add target to MY following list
      // ----------------------------------------------------------

      await _addToChunk(
        profileId: myProfileId,
        column: 'following_profile_ids',
        targetProfileId: targetProfileId,
      );

      // ----------------------------------------------------------
      // Add ME to TARGET's followers list
      // ----------------------------------------------------------

      await _addToChunk(
        profileId: targetProfileId,
        column: 'follower_profile_ids',
        targetProfileId: myProfileId,
      );

      debugPrint('[FOLLOW] Follow completed');

      return true;
    } catch (e, stackTrace) {
      debugPrint('[FOLLOW] Follow error: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ============================================================
  // UNFOLLOW USER
  // ============================================================

  Future<bool> unfollowUser(String targetProfileId) async {
    try {
      final myProfileId = await CurrentUserService.instance.getProfileId();

      if (myProfileId == null) {
        return false;
      }

      debugPrint('[FOLLOW] Unfollow $myProfileId → $targetProfileId');

      // Remove target from MY following list.
      await _removeFromChunks(
        profileId: myProfileId,
        column: 'following_profile_ids',
        targetProfileId: targetProfileId,
      );

      // Remove ME from TARGET's followers list.
      await _removeFromChunks(
        profileId: targetProfileId,
        column: 'follower_profile_ids',
        targetProfileId: myProfileId,
      );

      debugPrint('[FOLLOW] Unfollow completed');

      return true;
    } catch (e, stackTrace) {
      debugPrint('[FOLLOW] Unfollow error: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ============================================================
  // ADD TO CHUNK
  // ============================================================

  Future<void> _addToChunk({
    required String profileId,
    required String column,
    required String targetProfileId,
  }) async {
    final rows = await _followChunks
        .select('id, profile_id, chunk, $column')
        .eq('profile_id', profileId)
        .order('chunk', ascending: true);

    // ----------------------------------------------------------
    // Already exists?
    // ----------------------------------------------------------

    for (final row in rows) {
      final ids = row[column];

      if (ids is List && ids.any((id) => id?.toString() == targetProfileId)) {
        debugPrint('[FOLLOW] Already exists in $column');
        return;
      }
    }

    // ----------------------------------------------------------
    // Add to existing chunk
    // ----------------------------------------------------------

    for (final row in rows) {
      final ids = List<String>.from(
        (row[column] as List?)?.map((e) => e.toString()) ?? [],
      );

      if (ids.length < 100) {
        ids.add(targetProfileId);

        await _followChunks.update({column: ids}).eq('id', row['id']);

        return;
      }
    }

    // ----------------------------------------------------------
    // Create new chunk
    // ----------------------------------------------------------

    final nextChunk = rows.isEmpty
        ? 1
        : ((rows.last['chunk'] as num?)?.toInt() ?? 0) + 1;

    await _followChunks.insert({
      'profile_id': profileId,
      'chunk': nextChunk,
      column: [targetProfileId],
    });
  }

  // ============================================================
  // REMOVE FROM CHUNKS
  // ============================================================

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
        await _followChunks.delete().eq('id', row['id']);
      } else {
        await _followChunks.update({column: ids}).eq('id', row['id']);
      }

      return;
    }
  }
}
