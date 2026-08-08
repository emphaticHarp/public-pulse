import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/core/services/current_user_service.dart';

class FollowRepository {
  FollowRepository._();

  static final FollowRepository instance = FollowRepository._();

  final _client = Supabase.instance.client;

  Future<Set<String>> getFollowingIds() async {
    final user = _client.auth.currentUser;

    if (user == null) return {};

    final profileId = await CurrentUserService.instance.getProfileId();

    if (profileId == null) {
      return <String>{};
    }

    final rows = await _client
        .from('user_follow2_chunked')
        .select('following_profile_ids')
        .eq('profile_id', profileId);

    final Set<String> ids = {};

    for (final row in rows) {
      final list = row['following_profile_ids'];

      if (list != null) {
        ids.addAll(List<String>.from(list));
      }
    }

    return ids;
  }

  Future<bool> followUser(String followingProfileId) async {
    try {
      debugPrint(
        '[FOLLOW] Calling follow_user with '
        'p_following_profile_id = $followingProfileId',
      );

      final response = await _client.rpc(
        'follow_user',
        params: {'p_following_profile_id': followingProfileId},
      );

      debugPrint('[FOLLOW] RPC response = $response');

      return true;
    } catch (e, stackTrace) {
      debugPrint('[FOLLOW] Follow Error: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  Future<bool> unfollowUser(String followingProfileId) async {
    try {
      await _client.rpc(
        'unfollow_user',
        params: {'p_following_profile_id': followingProfileId},
      );

      return true;
    } catch (e) {
      print("Unfollow Error: $e");
      return false;
    }
  }
}
