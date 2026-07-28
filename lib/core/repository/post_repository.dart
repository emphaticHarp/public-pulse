import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/model/post_model.dart';

class PostRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> getCurrentProfileId() async {
    debugPrint('[DEBUG-REPO] getCurrentProfileId: starting');
    final user = _supabase.auth.currentUser;
    debugPrint('[DEBUG-REPO] getCurrentProfileId: currentUser = ${user?.id ?? "null"}');

    if (user == null) {
      debugPrint('[DEBUG-REPO] getCurrentProfileId: user is null, returning null');
      return null;
    }

    try {
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      debugPrint('[DEBUG-REPO] getCurrentProfileId: profile lookup result = $profile');
      return profile?['id'];
    } catch (e) {
      debugPrint('[DEBUG-REPO] getCurrentProfileId: ERROR = $e');
      return null;
    }
  }

  // it will check in user_follows table that whether the user which is logged in is followed by which user

  Future<bool> isFollowing(
    String currentProfileId,
    String postOwnerProfileId,
  ) async {
    debugPrint('[DEBUG-REPO] isFollowing: current=$currentProfileId, owner=$postOwnerProfileId');
    try {
      final follow = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_profile_id', currentProfileId)
          .eq('following_profile_id', postOwnerProfileId)
          .eq('status', 'ACCEPTED')
          .maybeSingle();

      debugPrint('[DEBUG-REPO] isFollowing: result = ${follow != null}');
      return follow != null;
    } catch (e) {
      debugPrint('[DEBUG-REPO] isFollowing: ERROR = $e');
      return false;
    }
  }

  Future<List<PostModel>> getMyPosts() async {
  debugPrint('[DEBUG-REPO] getMyPosts: starting');

  final currentProfileId = await getCurrentProfileId();

  if (currentProfileId == null) {
    debugPrint('[DEBUG-REPO] getMyPosts: currentProfileId is null');
    return [];
  }

  try {
    final response = await _supabase
        .from('posts')
        .select('''
          id,
          profile_id,
          caption,
          location_name,
          visibility,
          like_count,
          comment_count,
          share_count,
          save_count,
          view_count,
          created_at,

          profile:profiles(
            username,
            display_name,
            avatar_path,
            is_private
          ),

          media:post_media(
            storage_path,
            thumbnail_path,
            media_type,
            media_order
          )
        ''')
        .eq('profile_id', currentProfileId)
        .eq('status', 'ACTIVE')
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false);

    return response.map((e) => PostModel.fromJson(e)).toList();
  } catch (e) {
    debugPrint('[DEBUG-REPO] getMyPosts ERROR: $e');
    return [];
  }
}
}

