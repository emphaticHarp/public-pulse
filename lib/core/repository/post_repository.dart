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

  Future<PostPage> getInitialPosts({int limit = 10}) async {
    debugPrint('[DEBUG-REPO] getInitialPosts: Starting...');
    try {
      debugPrint('[DEBUG-REPO] getPosts: Fetching from Supabase...');

      // 2️⃣ Fetch latest posts from Supabase
      var query = _supabase
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
          .filter('deleted_at', 'is', null);

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint(
        '[DEBUG-REPO] getPosts: Supabase response length = ${response.length}',
      );
      debugPrint('[DEBUG-REPO] getPosts: Raw Supabase data: $response');

      final posts = response
          .map<PostModel>((e) => PostModel.fromJson(e))
          .toList();

      debugPrint('[DEBUG-REPO] getPosts: Parsed ${posts.length} posts');
      debugPrint(
        '[DEBUG-REPO] getPosts: Parsed post IDs: ${posts.map((e) => e.id).toList()}',
      );

      // Merge cached + fresh posts

      final String? nextCursor = posts.isNotEmpty
          ? posts.last.createdAt.toIso8601String()
          : null;

      final bool hasMore = posts.length == limit;

      debugPrint('[DEBUG-REPO] Returning ${posts.length} posts');

      return PostPage(posts: posts, nextCursor: nextCursor, hasMore: hasMore);
    } catch (e, stackTrace) {
      debugPrint('[DEBUG-REPO] getInitialPosts ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      return PostPage(posts: [], nextCursor: null, hasMore: false);
    }
  }

  Future<PostPage> getMorePosts({
    required String cursor,
    int limit = 10,
  }) async {
    debugPrint('[DEBUG-REPO] getMorePosts');

    var query = _supabase
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
    debugPrint('[DEBUG-REPO] getMyPosts: starting');

    try {
      final currentProfileId = await getCurrentProfileId();

      if (currentProfileId == null) {
        debugPrint('[DEBUG-REPO] getMyPosts: profile id is null');
        return [];
      }

      debugPrint('[DEBUG-REPO] getMyPosts: profileId = $currentProfileId');

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

      debugPrint('[DEBUG-REPO] getMyPosts: fetched ${response.length} posts');

      return response.map((e) => PostModel.fromJson(e)).toList();
    } catch (e, stackTrace) {
      debugPrint('[DEBUG-REPO] getMyPosts ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<PostModel>> getNewPosts({required String latestCreatedAt}) async {
    debugPrint('[DEBUG-REPO] Checking posts newer than $latestCreatedAt');

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
        .gt('created_at', latestCreatedAt)
        .order('created_at', ascending: false);

    final posts = response
        .map<PostModel>((e) => PostModel.fromJson(e))
        .toList();

    debugPrint('[DEBUG-REPO] New posts found = ${posts.length}');

    return posts;
  }
}
