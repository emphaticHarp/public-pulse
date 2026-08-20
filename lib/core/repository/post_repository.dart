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
    CurrentUserService.instance.clear();
  }

  // ============================================================
  // INITIAL POSTS
  // ============================================================

  Future<PostPage> getInitialPosts({int limit = 10}) async {
    try {
      final currentProfileId = await getCurrentProfileId();

      if (currentProfileId == null) {
        return PostPage(posts: [], nextCursor: null, hasMore: false);
      }

      final response = await _supabase
          .from('posts')
          .select('''
          id,
          profile_id,
          caption,
          location_name,
          latitude,
          longitude,
          visibility,
          like_count,
          comment_count,
          share_count,
          save_count,
          view_count,
          created_at,

          profile:profiles(
            user_id,
            username,
            display_name,
            avatar_path,
            avatar_thumbnail_path,
            is_private
          ),

          media:post_media(
            storage_path,
            thumbnail_path,
            media_type,
            media_order,
            width,
            height
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
          // ✅ CURRENT USER ONLY
          .eq('my_like.profile_id', currentProfileId)
          .eq('my_save.profile_id', currentProfileId)
          .order('created_at', ascending: false)
          .limit(limit);

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
    } catch (_) {
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
    try {
      final currentProfileId = await getCurrentProfileId();

      if (currentProfileId == null) {
        return PostPage(posts: [], nextCursor: null, hasMore: false);
      }

      final response = await _supabase
          .from('posts')
          .select('''
          id,
          profile_id,
          caption,
          location_name,
          latitude,
          longitude,
          visibility,
          like_count,
          comment_count,
          share_count,
          save_count,
          view_count,
          created_at,

          profile:profiles(
            user_id,
            username,
            display_name,
            avatar_path,
            avatar_thumbnail_path,
            is_private
          ),

          media:post_media(
            storage_path,
            thumbnail_path,
            media_type,
            media_order,
            width,
            height
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
          .eq('my_like.profile_id', currentProfileId)
          .eq('my_save.profile_id', currentProfileId)
          .lt('created_at', cursor)
          .order('created_at', ascending: false)
          .limit(limit);

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
    } catch (_) {
      return PostPage(posts: [], nextCursor: null, hasMore: false);
    }
  }

  // ============================================================
  // MY POSTS
  // ============================================================

  Future<List<PostModel>> getMyPosts() async {
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
          latitude,
          longitude,
          visibility,
          like_count,
          comment_count,
          share_count,
          save_count,
          view_count,
          created_at,

          profile:profiles(
            user_id,
            username,
            display_name,
            avatar_path,
            avatar_thumbnail_path,
            is_private
          ),

          media:post_media(
            storage_path,
            thumbnail_path,
            media_type,
            media_order,
            width,
            height
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
          .eq('my_like.profile_id', currentProfileId)
          .eq('my_save.profile_id', currentProfileId)
          .order('created_at', ascending: false);

      return response
          .map<PostModel>((data) => PostModel.fromJson(data, currentProfileId))
          .toList();
    } catch (_) {
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
    try {
      final currentProfileId = await getCurrentProfileId();

      if (currentProfileId == null) {
        return [];
      }

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
              user_id,
              username,
              display_name,
              avatar_path,
              avatar_thumbnail_path,
              is_private
            ),

            media:post_media(
              storage_path,
              thumbnail_path,
              media_type,
              media_order,
              width,
              height
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

      final posts = <PostModel>[];

      for (final row in response) {
        final post = row['post'];

        if (post == null) {
          continue;
        }

        if (post['status'] != 'ACTIVE') {
          continue;
        }

        if (post['deleted_at'] != null) {
          continue;
        }

        try {
          final postModel = PostModel.fromJson(
            Map<String, dynamic>.from(post),
            currentProfileId,
          );

          posts.add(postModel);
        } catch (_) {
          // Intentionally ignored.
        }
      }

      return posts;
    } catch (_) {
      return [];
    }
  }
  // ============================================================
  // NEW POSTS
  // ============================================================

  Future<List<PostModel>> getNewPosts({required String latestCreatedAt}) async {
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
          latitude,
          longitude,
          visibility,
          like_count,
          comment_count,
          share_count,
          save_count,
          view_count,
          created_at,

          profile:profiles(
            user_id,
            username,
            display_name,
            avatar_path,
            avatar_thumbnail_path,
            is_private
          ),

          media:post_media(
            storage_path,
            thumbnail_path,
            media_type,
            media_order,
            width,
            height
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
          .eq('my_like.profile_id', currentProfileId)
          .eq('my_save.profile_id', currentProfileId)
          .gt('created_at', latestCreatedAt)
          .order('created_at', ascending: false);

      return response
          .map<PostModel>((data) => PostModel.fromJson(data, currentProfileId))
          .toList();
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {
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

      return response.isNotEmpty;
    } on PostgrestException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
