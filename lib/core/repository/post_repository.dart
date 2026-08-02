import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/model/post_model.dart';

class PostPage {
  final List<PostModel> posts;
  final String? nextCursor;
  final bool hasMore;

  PostPage({
    required this.posts,
    required this.nextCursor,
    required this.hasMore,
  });
}

class PostRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> getCurrentProfileId() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      return profile?['id'];
    } catch (e) {
      debugPrint('[ERROR] getCurrentProfileId: $e');
      return null;
    }
  }

  Future<PostPage> getInitialPosts({int limit = 10}) async {
    debugPrint("======== getInitialPosts CALLED ========");
    try {
      var query = _supabase
          .from('posts')
          .select('''id,
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
          .filter('deleted_at', 'is', null);

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final posts = response
          .map<PostModel>((e) => PostModel.fromJson(e))
          .toList();

      final String? nextCursor = posts.isNotEmpty
          ? posts.last.createdAt.toIso8601String()
          : null;

      final bool hasMore = posts.length == limit;

      return PostPage(posts: posts, nextCursor: nextCursor, hasMore: hasMore);
    } catch (e, stackTrace) {
      debugPrint('[ERROR] getInitialPosts: $e');
      debugPrintStack(stackTrace: stackTrace);

      return PostPage(posts: [], nextCursor: null, hasMore: false);
    }
  }

  Future<PostPage> getMorePosts({
    required String cursor,
    int limit = 10,
  }) async {
    debugPrint("======== getMorePosts CALLED ========");
    var query = _supabase
        .from('posts')
        .select('''id,
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
        .lt('created_at', cursor);

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    final posts = response
        .map<PostModel>((e) => PostModel.fromJson(e))
        .toList();

    final nextCursor = posts.isNotEmpty
        ? posts.last.createdAt.toIso8601String()
        : null;

    return PostPage(
      posts: posts,
      nextCursor: nextCursor,
      hasMore: posts.length == limit,
    );
  }

  Future<List<PostModel>> getMyPosts() async {
    debugPrint("======== getMyPosts CALLED ========");
    try {
      final currentProfileId = await getCurrentProfileId();

      if (currentProfileId == null) {
        return [];
      }

      final response = await _supabase
          .from('posts')
          .select('''id,
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
    } catch (e, stackTrace) {
      debugPrint('[ERROR] getMyPosts: $e');
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<PostModel>> getNewPosts({required String latestCreatedAt}) async {
    debugPrint("======== getNewPosts CALLED ========");
    final response = await _supabase
        .from('posts')
        .select('''id,
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
        .gt('created_at', latestCreatedAt)
        .order('created_at', ascending: false);

    final posts = response
        .map<PostModel>((e) => PostModel.fromJson(e))
        .toList();

    return posts;
  }

  Future<bool> isPostLiked(String postId) async {
    final profileId = await getCurrentProfileId();

    if (profileId == null) return false;

    final data = await _supabase
        .from('post_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('profile_id', profileId)
        .maybeSingle();

    return data != null;
  }

  Future<void> likePost(String postId) async {
    final profileId = await getCurrentProfileId();

    if (profileId == null) return;

    await _supabase.from('post_likes').insert({
      'post_id': postId,
      'profile_id': profileId,
    });

    await _supabase.rpc(
      'increment_post_like_count',
      params: {'post_id_input': postId},
    );
  }

  Future<void> unlikePost(String postId) async {
    final profileId = await getCurrentProfileId();

    if (profileId == null) return;

    await _supabase
        .from('post_likes')
        .delete()
        .eq('post_id', postId)
        .eq('profile_id', profileId);

    await _supabase.rpc(
      'decrement_post_like_count',
      params: {'post_id_input': postId},
    );
  }


  // like api with toggle functionality

  Future<bool> toggleLike({
    required String postId,
    required bool isLiked,
  }) async {
    try {
      final profileId = await getCurrentProfileId();

      if (profileId == null) return false;

      if (isLiked) {
        // Unlike
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('profile_id', profileId);

        await _supabase.rpc(
          'decrement_like_count',
          params: {'p_post_id': postId},
        );
      } else {
        // Like
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'profile_id': profileId,
        });

        await _supabase.rpc(
          'increment_like_count',
          params: {'p_post_id': postId},
        );
      }

      return true;
    } catch (e) {
      debugPrint("Like Error: $e");
      return false;
    }
  }
}
