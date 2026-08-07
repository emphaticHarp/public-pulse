import 'package:supabase_flutter/supabase_flutter.dart';

class FollowRepository {
  FollowRepository._();

  static final FollowRepository instance = FollowRepository._();

  final _client = Supabase.instance.client;

  Future<Set<String>> getFollowingIds() async {
    final user = _client.auth.currentUser;

    if (user == null) return {};

    final profile = await _client
        .from('profiles')
        .select('id')
        .eq('user_id', user.id)
        .single();

    final profileId = profile['id'];

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

  Future<void> followUser(String followingProfileId) async {
    await _client.rpc(
      'follow_user',
      params: {'p_following_profile_id': followingProfileId},
    );
  }

  Future<void> unfollowUser(String followingProfileId) async {
    await _client.rpc(
      'unfollow_user',
      params: {'p_following_profile_id': followingProfileId},
    );
  }
}
