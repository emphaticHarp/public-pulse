import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/model/post_model.dart';
import 'package:public_pulse/core/cache/cache_manager.dart';

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

  List<PostModel> _mergePosts(List<PostModel> cached, List<PostModel> fresh) {
    final Map<String, PostModel> map = {};

    // Old cache
    for (final post in cached) {
      map[post.id] = post;
    }

    // Fresh posts overwrite cached version
    for (final post in fresh) {
      map[post.id] = post;
    }

    final merged = map.values.toList();

    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return merged;
  }

  Future<PostPage> getPosts({String? cursor, int limit = 10}) async {
    debugPrint('[DEBUG-REPO] getPosts: Starting...');
    try {
      final cachedPosts = CacheManager.getCachedPosts();

      debugPrint('[DEBUG-REPO] Cached posts = ${cachedPosts.length}');

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

      if (cursor != null) {
        query = query.lt('created_at', cursor);
      }

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
      final mergedPosts = _mergePosts(cachedPosts, posts);

      debugPrint('[DEBUG-REPO] Merged posts count = ${mergedPosts.length}');

      final String? nextCursor = posts.isNotEmpty
          ? posts.last.createdAt.toIso8601String()
          : null;

      final bool hasMore = posts.length == limit;

      // Save merged posts into Hive
      await CacheManager.cachePosts(
        mergedPosts,
        nextCursor: nextCursor,
        hasMore: hasMore,
      );

      debugPrint('[DEBUG-REPO] Returning ${mergedPosts.length} merged posts');

      return PostPage(
        posts: mergedPosts,
        nextCursor: nextCursor,
        hasMore: hasMore,
      );
    } catch (e, stackTrace) {
      debugPrint('[DEBUG-REPO] getPosts ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      // 4️⃣ If Supabase fails, try loading cached posts
      debugPrint(
        '[DEBUG-REPO] getPosts: Falling back to cached posts due to error',
      );
      final cachedPosts = CacheManager.getCachedPosts();

      if (cachedPosts.isNotEmpty) {
        debugPrint(
          '[DEBUG-REPO] getPosts: Using ${cachedPosts.length} offline cached posts',
        );
        return PostPage(posts: cachedPosts, nextCursor: null, hasMore: false);
      }

      debugPrint(
        '[DEBUG-REPO] getPosts: No cached posts available, returning empty list',
      );
      return PostPage(posts: [], nextCursor: null, hasMore: false);
    }
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
}
