import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:public_pulse/model/post_model.dart';
import 'package:public_pulse/model/comment_model.dart';
import 'package:public_pulse/model/profile_model.dart';

import 'hive_boxes.dart';
import 'cache_keys.dart';

class CacheManager {
  // Hive box for cached posts.
  static Box get _postBox => Hive.box(HiveBoxes.cachedPosts);

  // Save posts and the current timestamp.
  static Future<void> cachePosts(
    List<PostModel> posts, {
    String? nextCursor,
    bool hasMore = true,
  }) async {
    final postsJson = posts.map((e) => e.toJson()).toList();

    await _postBox.put(CacheKeys.posts, postsJson);
    await _postBox.put(
      CacheKeys.timestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
    await _postBox.put(CacheKeys.nextCursor, nextCursor);
    await _postBox.put(CacheKeys.hasMore, hasMore);

    debugPrint(
      '[CACHE] Saved to Hive: ${posts.length} posts, ids: ${posts.map((e) => e.id).toList()}',
    );
  }

  // Load cached posts if available.
  static List<PostModel> getCachedPosts() {
    debugPrint('[CACHE] getCachedPosts: Starting...');

    final cached = _postBox.get(CacheKeys.posts);

    if (cached == null) {
      debugPrint(
        '[CACHE] getCachedPosts: cached is NULL, returning empty list',
      );
      return [];
    }

    debugPrint(
      '[CACHE] getCachedPosts: cached raw length = ${(cached as List).length}',
    );

    final List<PostModel> posts = [];
    for (int i = 0; i < cached.length; i++) {
      try {
        final postData = Map<String, dynamic>.from(cached[i]);
        final post = PostModel.fromCache(postData);
        posts.add(post);
      } catch (e) {
        debugPrint('[CACHE] getCachedPosts: ERROR parsing post $i: $e');
      }
    }

    debugPrint(
      '[CACHE] Loaded from Hive: ${posts.length} posts, ids: ${posts.map((e) => e.id).toList()}',
    );
    return posts;
  }

  static bool getHasMore() {
    return _postBox.get(CacheKeys.hasMore, defaultValue: true);
  }

  static String? getNextCursor() {
    return _postBox.get(CacheKeys.nextCursor);
  }

  // Remove all cached posts.
  static Future<void> clearPostCache() async {
    debugPrint('[CACHE] clearPostCache: Clearing all cached posts');
    await _postBox.clear();
    debugPrint('[CACHE] clearPostCache: Cache cleared');
  }

  // ---------------- COMMENTS CACHE ----------------

  static Box get _commentBox => Hive.box(HiveBoxes.cachedComments);

  static String _commentKey(String postId) => 'comments_$postId';

  static Future<void> cacheComments(
    String postId,
    List<CommentModel> comments,
  ) async {
    await _commentBox.put(
      _commentKey(postId),
      comments.map((e) => e.toMap()).toList(),
    );
  }

  static List<CommentModel> getCachedComments(String postId) {
    final data = _commentBox.get(_commentKey(postId));

    if (data == null) return [];

    return (data as List)
        .map((e) => CommentModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> clearComments(String postId) async {
    await _commentBox.delete(_commentKey(postId));
  }

  // ====================== FOLLOW CACHE ======================
  static Box get _followingBox => Hive.box(HiveBoxes.cachedFollowing);

  static Future cacheFollowingIds(Set<String> ids) async {
    await _followingBox.put(CacheKeys.followingIds, ids.toList());
  }

  static Set<String> getCachedFollowingIds() {
    final data = _followingBox.get(CacheKeys.followingIds);

    if (data == null) {
      return {};
    }

    return Set<String>.from(data);
  }

  static Future<void> clearFollowingCache() async {
    await _followingBox.delete(CacheKeys.followingIds);
  }

  // ================= USER PROFILE CACHE =================

  static Box get _userProfileBox => Hive.box(HiveBoxes.cachedUserProfile);

  static Future cacheUserProfile(ProfileModel profile) async {
    await _userProfileBox.put(CacheKeys.userProfile, profile.toJson());

    await _userProfileBox.put(
      CacheKeys.userProfileTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );

    debugPrint("[PROFILE CACHE] Saved");
  }

  static ProfileModel? getCachedUserProfile() {
    final data = _userProfileBox.get(CacheKeys.userProfile);

    if (data == null) return null;

    debugPrint("[PROFILE CACHE] Loaded");

    return ProfileModel.fromJson(Map<String, dynamic>.from(data));
  }

  static Future clearUserProfileCache() async {
    await _userProfileBox.clear();
  }

  // ============================================================
  // PROFILE POSTS CACHE
  // ============================================================

  static const Duration _profilePostsCacheDuration = Duration(days: 5);

  // ------------------------------------------------------------
  // MY POSTS
  // ------------------------------------------------------------

  static Box get _myPostsBox => Hive.box(HiveBoxes.cachedMyPosts);

  static Future<void> cacheMyPosts(List<PostModel> posts) async {
    final postsJson = posts.map((post) => post.toJson()).toList();

    await _myPostsBox.put(CacheKeys.myPosts, postsJson);

    await _myPostsBox.put(
      CacheKeys.myPostsTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );

    debugPrint('[PROFILE CACHE] My posts cached: ${posts.length}');
  }

  static List<PostModel> getCachedMyPosts() {
    final data = _myPostsBox.get(CacheKeys.myPosts);

    if (data == null) {
      debugPrint('[PROFILE CACHE] No cached my posts');
      return [];
    }

    final timestamp = _myPostsBox.get(CacheKeys.myPostsTimestamp);

    if (timestamp == null) {
      debugPrint('[PROFILE CACHE] My posts timestamp missing');
      return [];
    }

    final age = DateTime.now().millisecondsSinceEpoch - (timestamp as int);

    if (age > _profilePostsCacheDuration.inMilliseconds) {
      debugPrint('[PROFILE CACHE] My posts cache expired');

      clearMyPostsCache();

      return [];
    }

    try {
      final cachedList = data as List;

      final posts = <PostModel>[];

      for (final item in cachedList) {
        try {
          final postData = Map<String, dynamic>.from(item);

          posts.add(PostModel.fromCache(postData));
        } catch (e) {
          debugPrint('[PROFILE CACHE] My post parse error: $e');
        }
      }

      debugPrint('[PROFILE CACHE] Loaded ${posts.length} my posts');

      return posts;
    } catch (e) {
      debugPrint('[PROFILE CACHE] Failed loading my posts: $e');

      return [];
    }
  }

  static Future<void> clearMyPostsCache() async {
    await _myPostsBox.clear();

    debugPrint('[PROFILE CACHE] My posts cache cleared');
  }

  // ------------------------------------------------------------
  // SAVED POSTS
  // ------------------------------------------------------------

  static Box get _savedPostsBox => Hive.box(HiveBoxes.cachedSavedPosts);

  static Future<void> cacheSavedPosts(List<PostModel> posts) async {
    final postsJson = posts.map((post) => post.toJson()).toList();

    await _savedPostsBox.put(CacheKeys.savedPosts, postsJson);

    await _savedPostsBox.put(
      CacheKeys.savedPostsTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );

    debugPrint('[PROFILE CACHE] Saved posts cached: ${posts.length}');
  }

  static List<PostModel> getCachedSavedPosts() {
    final data = _savedPostsBox.get(CacheKeys.savedPosts);

    if (data == null) {
      debugPrint('[PROFILE CACHE] No cached saved posts');

      return [];
    }

    final timestamp = _savedPostsBox.get(CacheKeys.savedPostsTimestamp);

    if (timestamp == null) {
      debugPrint('[PROFILE CACHE] Saved posts timestamp missing');

      return [];
    }

    final age = DateTime.now().millisecondsSinceEpoch - (timestamp as int);

    if (age > _profilePostsCacheDuration.inMilliseconds) {
      debugPrint('[PROFILE CACHE] Saved posts cache expired');

      clearSavedPostsCache();

      return [];
    }

    try {
      final cachedList = data as List;

      final posts = <PostModel>[];

      for (final item in cachedList) {
        try {
          final postData = Map<String, dynamic>.from(item);

          posts.add(PostModel.fromCache(postData));
        } catch (e) {
          debugPrint('[PROFILE CACHE] Saved post parse error: $e');
        }
      }

      debugPrint('[PROFILE CACHE] Loaded ${posts.length} saved posts');

      return posts;
    } catch (e) {
      debugPrint('[PROFILE CACHE] Failed loading saved posts: $e');

      return [];
    }
  }

  static Future<void> clearSavedPostsCache() async {
    await _savedPostsBox.clear();

    debugPrint('[PROFILE CACHE] Saved posts cache cleared');
  }

  // ------------------------------------------------------------
  // CLEAR BOTH PROFILE POST CACHES
  // ------------------------------------------------------------

  static Future<void> clearProfilePostsCache() async {
    await _myPostsBox.clear();
    await _savedPostsBox.clear();

    debugPrint('[PROFILE CACHE] My + saved posts caches cleared');
  }

  static Future<void> clearUserData() async {
    debugPrint('[CACHE] ===============================');
    debugPrint('[CACHE] CLEARING USER DATA');
    debugPrint('[CACHE] ===============================');

    // Home feed
    await clearPostCache();

    // User profile
    await clearUserProfileCache();

    // Following IDs
    await clearFollowingCache();

    // My posts
    try {
      await Hive.box(HiveBoxes.cachedMyPosts).clear();
      debugPrint('[CACHE] My posts cleared');
    } catch (e) {
      debugPrint('[CACHE] My posts clear error: $e');
    }

    // Saved posts
    try {
      await Hive.box(HiveBoxes.cachedSavedPosts).clear();
      debugPrint('[CACHE] Saved posts cleared');
    } catch (e) {
      debugPrint('[CACHE] Saved posts clear error: $e');
    }

    // Followers / Following
    try {
      await Hive.box(HiveBoxes.cachedFollowersFollowing).clear();

      debugPrint('[CACHE] Followers/following cache cleared');
    } catch (e) {
      debugPrint('[CACHE] Followers/following clear error: $e');
    }

    debugPrint('[CACHE] ===============================');
    debugPrint('[CACHE] USER DATA CLEARED');
    debugPrint('[CACHE] ===============================');
  }
}
