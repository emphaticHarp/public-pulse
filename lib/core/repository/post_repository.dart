import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/model/post_model.dart';

class PostRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> getCurrentProfileId() async {
    debugPrint('[DEBUG-REPO] getCurrentProfileId: starting');
    final user = _supabase.auth.currentUser;
    debugPrint(
      '[DEBUG-REPO] getCurrentProfileId: currentUser = ${user?.id ?? "null"}',
    );

    if (user == null) {
      debugPrint(
        '[DEBUG-REPO] getCurrentProfileId: user is null, returning null',
      );
      return null;
    }

    try {
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      debugPrint(
        '[DEBUG-REPO] getCurrentProfileId: profile lookup result = $profile',
      );
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
    debugPrint(
      '[DEBUG-REPO] isFollowing: current=$currentProfileId, owner=$postOwnerProfileId',
    );
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

  Future<List<PostModel>> getPosts() async {
    debugPrint('[DEBUG-REPO] getPosts: starting');
    final currentProfileId = await getCurrentProfileId();
    debugPrint('[DEBUG-REPO] getPosts: currentProfileId = $currentProfileId');

    try {
      debugPrint('[DEBUG-REPO] getPosts: executing Supabase query...');
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
          .eq('status', 'ACTIVE')
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      debugPrint(
        '[DEBUG-REPO] getPosts: query returned ${response.length} raw posts',
      );

      // Loop through each post, check if the current user follows the post owner, then convert it into a PostModel.
      final List<PostModel> posts = [];

      for (final json in response) {
        final postOwnerId = json['profile_id'];

        debugPrint(
          '[DEBUG-REPO] getPosts: processing post id=${json["id"]}, owner=$postOwnerId',
        );
        debugPrint(
          '[DEBUG-REPO] getPosts: raw post JSON keys = ${json.keys.toList()}',
        );

        final following = currentProfileId != null
            ? await isFollowing(currentProfileId, postOwnerId)
            : false;
        //// Get whether the post owner's profile is private or public.
        final profile = json['profile'];
        debugPrint('[DEBUG-REPO] getPosts: profile data = $profile');
        final isPrivate = profile != null
            ? (profile['is_private'] as bool)
            : false;
        // Get this post's visibility setting (PUBLIC, FOLLOWERS, etc.).
        final visibility = json['visibility'] as String? ?? 'UNKNOWN';
        debugPrint(
          '[DEBUG-REPO] getPosts: isPrivate=$isPrivate, visibility=$visibility, following=$following',
        );

        // Show public posts to everyone and private posts only to followers.
        if (!isPrivate) {
          // case 1: Public account (Public account PUBLIC post,Everyone can see it)
          if (visibility == 'PUBLIC') {
            debugPrint(
              '[DEBUG-REPO] getPosts: adding PUBLIC post from public account',
            );
            posts.add(PostModel.fromJson(json));
            //case 2 Public account , FOLLOWERS post , Only followers can see it
          } else if (visibility == 'FOLLOWERS' && following) {
            debugPrint(
              '[DEBUG-REPO] getPosts: adding FOLLOWERS post (user is following)',
            );
            posts.add(PostModel.fromJson(json));
          } else {
            debugPrint(
              '[DEBUG-REPO] getPosts: SKIPPING post - visibility=$visibility, following=$following',
            );
          }
        } else {
          // Private account Only followers can see any posts.
          if (following) {
            debugPrint(
              '[DEBUG-REPO] getPosts: adding post from private account (user is following)',
            );
            posts.add(PostModel.fromJson(json));
          } else {
            debugPrint(
              '[DEBUG-REPO] getPosts: SKIPPING post from private account - not following',
            );
          }
        }
      }

      debugPrint(
        '[DEBUG-REPO] getPosts: returning ${posts.length} filtered posts',
      );
      return posts;
    } catch (e, stackTrace) {
      debugPrint('[DEBUG-REPO] getPosts: CATCH ERROR = $e');
      debugPrint('[DEBUG-REPO] getPosts: stackTrace = $stackTrace');
      return [];
    }
  }
}
