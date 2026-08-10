import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/core/services/current_user_service.dart';
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

  // ============================================================
  // CURRENT PROFILE ID CACHE
  // ============================================================

  String? _cachedProfileId;

  Future<String?>? _profileIdRequest;

  /// Gets the current user's profile ID.
  ///
  /// IMPORTANT:
  /// The first call hits Supabase.
  /// All subsequent calls use the in-memory cached ID.
  Future<String?> getCurrentProfileId() async {
    return await CurrentUserService.instance.getProfileId();
  }

  /// Call this when the authenticated user changes.
  void clearCurrentProfileIdCache() {
    _cachedProfileId = null;
    _profileIdRequest = null;

    debugPrint('[PROFILE-ID] Cache cleared');
  }

  // ============================================================
  // INITIAL POSTS
  // ============================================================

  Future<PostPage> getInitialPosts({int limit = 10}) async {
    debugPrint('[REPO] getInitialPosts()');

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
                ),

                my_like:post_likes!left(
                  id,
                  profile_id,
                  post_id
                ),

                my_save:saved_posts!left(
                  id,
                  profile_id,
                  post_id
                )
                ''')
          .eq('status', 'ACTIVE')
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint(
        '[REPO] Initial response: '
        '${response.length}',
      );

      final currentProfileId = await getCurrentProfileId();

      final posts = response
          .map<PostModel>((data) => PostModel.fromJson(data, currentProfileId))
          .toList();

      final nextCursor = posts.isNotEmpty
          ? posts.last.createdAt.toIso8601String()
          : null;

      return PostPage(
        posts: posts,
        nextCursor: nextCursor,
        hasMore: posts.length == limit,
      );
    } catch (e, stackTrace) {
      debugPrint('[ERROR] getInitialPosts: $e');

      debugPrintStack(stackTrace: stackTrace);

      return PostPage(posts: [], nextCursor: null, hasMore: false);
    }
  }

  // ============================================================
  // MORE POSTS
  // ============================================================

  Future<PostPage> getMorePosts({
    required String cursor,
    int limit = 10,
  }) async {
    debugPrint('[REPO] getMorePosts()');

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
                ),

                my_like:post_likes!left(
                  id,
                  profile_id,
                  post_id
                ),

                my_save:saved_posts!left(
                  id,
                  profile_id,
                  post_id
                )
                ''')
          .eq('status', 'ACTIVE')
          .filter('deleted_at', 'is', null)
          .lt('created_at', cursor)
          .order('created_at', ascending: false)
          .limit(limit);

      final currentProfileId = await getCurrentProfileId();

      final posts = response
          .map<PostModel>((data) => PostModel.fromJson(data, currentProfileId))
          .toList();

      final nextCursor = posts.isNotEmpty
          ? posts.last.createdAt.toIso8601String()
          : null;

      return PostPage(
        posts: posts,
        nextCursor: nextCursor,
        hasMore: posts.length == limit,
      );
    } catch (e, stackTrace) {
      debugPrint('[ERROR] getMorePosts: $e');

      debugPrintStack(stackTrace: stackTrace);

      return PostPage(posts: [], nextCursor: null, hasMore: false);
    }
  }

  // ============================================================
  // MY POSTS
  // ============================================================

  Future<List<PostModel>> getMyPosts() async {
    debugPrint('[REPO] getMyPosts()');

    try {
      final currentProfileId = await getCurrentProfileId();

      if (currentProfileId == null) {
        return [];
      }

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
                ),

                my_like:post_likes!left(
                  id,
                  profile_id,
                  post_id
                ),

                my_save:saved_posts!left(
                  id,
                  profile_id,
                  post_id
                )
                ''')
          .eq('profile_id', currentProfileId)
          .eq('status', 'ACTIVE')
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      return response
          .map<PostModel>((data) => PostModel.fromJson(data, currentProfileId))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('[ERROR] getMyPosts: $e');

      debugPrintStack(stackTrace: stackTrace);

      return [];
    }
  }

  // ============================================================
  // SAVED POSTS
  // ============================================================

  // ============================================================
  // SAVED POSTS
  // ============================================================

  Future<List<PostModel>> getSavedPosts() async {
    debugPrint('[REPO] getSavedPosts()');

    try {
      final currentProfileId = await getCurrentProfileId();

      if (currentProfileId == null) {
        debugPrint('[REPO] No current profile ID');
        return [];
      }

      debugPrint('[REPO] Loading saved posts for: $currentProfileId');

      final response = await _supabase
          .from('saved_posts')
          .select('''
          id,
          profile_id,
          post_id,
          created_at,

          post:posts(
            id,
            profile_id,
            caption,
            location_name,
            visibility,
            status,
            deleted_at,
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
            ),

            my_like:post_likes!left(
              id,
              profile_id,
              post_id
            )
          )
        ''')
          .eq('profile_id', currentProfileId)
          .order('created_at', ascending: false);

      debugPrint('[REPO] saved_posts rows returned: ${response.length}');

      final posts = <PostModel>[];

      for (final row in response) {
        final post = row['post'];

        if (post == null) {
          debugPrint('[REPO] Saved row has no post');
          continue;
        }

        if (post['status'] != 'ACTIVE') {
          debugPrint('[REPO] Skipping inactive post: ${post['id']}');
          continue;
        }

        if (post['deleted_at'] != null) {
          debugPrint('[REPO] Skipping deleted post: ${post['id']}');
          continue;
        }

        try {
          final postModel = PostModel.fromJson(
            Map<String, dynamic>.from(post),
            currentProfileId,
          );

          posts.add(postModel);
        } catch (e, stackTrace) {
          debugPrint('[REPO] Failed to convert saved post ${post['id']}: $e');
          debugPrintStack(stackTrace: stackTrace);
        }
      }

      debugPrint('[REPO] Saved posts loaded successfully: ${posts.length}');

      return posts;
    } catch (e, stackTrace) {
      debugPrint('[ERROR] getSavedPosts: $e');
      debugPrintStack(stackTrace: stackTrace);

      return [];
    }
  }
  // ============================================================
  // NEW POSTS
  // ============================================================

  Future<List<PostModel>> getNewPosts({required String latestCreatedAt}) async {
    debugPrint('[REPO] getNewPosts()');

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
                ),

                my_like:post_likes!left(
                  id,
                  profile_id,
                  post_id
                ),

                my_save:saved_posts!left(
                  id,
                  profile_id,
                  post_id
                )
                ''')
          .eq('status', 'ACTIVE')
          .filter('deleted_at', 'is', null)
          .gt('created_at', latestCreatedAt)
          .order('created_at', ascending: false);

      final currentProfileId = await getCurrentProfileId();

      return response
          .map<PostModel>((data) => PostModel.fromJson(data, currentProfileId))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('[ERROR] getNewPosts: $e');

      debugPrintStack(stackTrace: stackTrace);

      return [];
    }
  }

  // ============================================================
  // LIKE
  // ============================================================

  Future<bool> toggleLike({
    required String postId,
    required bool currentlyLiked,
  }) async {
    try {
      final profileId = await getCurrentProfileId();

      if (profileId == null) {
        return false;
      }

      if (currentlyLiked) {
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('profile_id', profileId);
      } else {
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'profile_id': profileId,
        });
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('[ERROR] toggleLike: $e');

      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<bool> toggleSave({
    required String postId,
    required bool currentlySaved,
  }) async {
    try {
      final profileId = await getCurrentProfileId();

      if (profileId == null) {
        return false;
      }

      if (currentlySaved) {
        await _supabase
            .from('saved_posts')
            .delete()
            .eq('post_id', postId)
            .eq('profile_id', profileId);
      } else {
        await _supabase.from('saved_posts').insert({
          'post_id': postId,
          'profile_id': profileId,
        });
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('[ERROR] toggleSave: $e');

      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<bool> deletePost(String postId) async {
    try {
      final response = await _supabase
          .from('posts')
          .delete()
          .eq('id', postId)
          .select();

      debugPrint('[REPO] DELETE RESPONSE: $response');

      return response.isNotEmpty;
    } on PostgrestException catch (e) {
      debugPrint('[REPO] DELETE POSTGRES ERROR: $e');

      return false;
    } catch (e, stackTrace) {
      debugPrint('[REPO] DELETE ERROR: $e');

      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }
}
