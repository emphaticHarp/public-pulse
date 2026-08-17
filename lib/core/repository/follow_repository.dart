import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/core/services/current_user_service.dart';

class FollowRepository {
  FollowRepository._();

  static final FollowRepository instance = FollowRepository._();

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

      await Supabase.instance.client.rpc(
        'follow_user',
        params: {'p_following_profile_id': targetProfileId},
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
        debugPrint('[FOLLOW] Current profile ID is null');
        return false;
      }

      if (myProfileId == targetProfileId) {
        debugPrint('[FOLLOW] Cannot unfollow yourself');
        return false;
      }

      debugPrint('[FOLLOW] Unfollow $myProfileId → $targetProfileId');

      await Supabase.instance.client.rpc(
        'unfollow_user',
        params: {'p_following_profile_id': targetProfileId},
      );

      debugPrint('[FOLLOW] Unfollow completed');

      return true;
    } catch (e, stackTrace) {
      debugPrint('[FOLLOW] Unfollow error: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }
}
