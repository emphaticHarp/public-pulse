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
      return {};
    }

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

    return ids;
  }

  // ============================================================
  // FOLLOW USER
  // ============================================================

  Future<bool> followUser(String targetProfileId) async {
    try {
      final myProfileId = await CurrentUserService.instance.getProfileId();

      if (myProfileId == null) {
        return false;
      }

      if (myProfileId == targetProfileId) {
        return false;
      }

      await Supabase.instance.client.rpc(
        'follow_user',
        params: {'p_following_profile_id': targetProfileId},
      );

      return true;
    } catch (e, stackTrace) {

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

      if (myProfileId == targetProfileId) {
        return false;
      }

      await Supabase.instance.client.rpc(
        'unfollow_user',
        params: {'p_following_profile_id': targetProfileId},
      );

      return true;
    } catch (e, stackTrace) {

      return false;
    }
  }
}
