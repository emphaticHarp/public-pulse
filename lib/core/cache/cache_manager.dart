import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:public_pulse/model/post_model.dart';
import 'package:public_pulse/model/comment_model.dart';
import 'package:public_pulse/model/profile_model.dart';

import 'hive_boxes.dart';
import 'cache_keys.dart';

class CacheManager {
  // Hive box for cached posts.
  static Box get _postBox => Hive.box(HiveBoxes.cachedPosts);

  // ============================================================
  // POST CACHE OWNER
  // ============================================================

  static const String _postCacheOwnerKey = 'post_cache_owner_profile_id';

  static String? getPostCacheOwnerProfileId() {
    return _postBox.get(_postCacheOwnerKey)?.toString();
  }

  static Future<void> setPostCacheOwnerProfileId(String profileId) async {
    await _postBox.put(_postCacheOwnerKey, profileId);
  }

  static bool hasPostCache() {
    return _postBox.containsKey(CacheKeys.posts);
  }

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
  }

  // Load cached posts if available.
  static List<PostModel> getCachedPosts() {
    final cached = _postBox.get(CacheKeys.posts);

    if (cached == null) {
      return [];
    }

    final List<PostModel> posts = [];
    for (int i = 0; i < cached.length; i++) {
      try {
        final postData = Map<String, dynamic>.from(cached[i]);
        final post = PostModel.fromCache(postData);
        posts.add(post);
      } catch (_) {
        // Intentionally ignored.
      }
    }

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
    await _postBox.clear();
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

  // ============================================================
  // USER PROFILE CACHE
  // ============================================================

  static Box get _userProfileBox => Hive.box(HiveBoxes.cachedUserProfile);

  // Cache for OTHER users' profiles.
  static Box get _profileBox => Hive.box(HiveBoxes.cachedProfiles);

  static const Duration _profileCacheDuration = Duration(days: 5);

  static Future<void> cacheUserProfile(ProfileModel profile) async {
    await _userProfileBox.put(CacheKeys.userProfile, profile.toJson());

    await _userProfileBox.put(
      CacheKeys.userProfileTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static ProfileModel? getCachedUserProfile() {
    final data = _userProfileBox.get(CacheKeys.userProfile);

    if (data == null) {
      return null;
    }

    try {
      final timestamp = _userProfileBox.get(CacheKeys.userProfileTimestamp);

      if (timestamp == null) {
        return null;
      }

      final age = DateTime.now().millisecondsSinceEpoch - (timestamp as int);

      if (age > _profileCacheDuration.inMilliseconds) {
        clearUserProfileCache();

        return null;
      }

      return ProfileModel.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearUserProfileCache() async {
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
  }

  static List<PostModel> getCachedMyPosts() {
    final data = _myPostsBox.get(CacheKeys.myPosts);

    if (data == null) {
      return [];
    }

    final timestamp = _myPostsBox.get(CacheKeys.myPostsTimestamp);

    if (timestamp == null) {
      return [];
    }

    final age = DateTime.now().millisecondsSinceEpoch - (timestamp as int);

    if (age > _profilePostsCacheDuration.inMilliseconds) {
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
        } catch (_) {
          // Intentionally ignored.
        }
      }

      return posts;
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearMyPostsCache() async {
    await _myPostsBox.clear();
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
  }

  static List<PostModel> getCachedSavedPosts() {
    final data = _savedPostsBox.get(CacheKeys.savedPosts);

    if (data == null) {
      return [];
    }

    final timestamp = _savedPostsBox.get(CacheKeys.savedPostsTimestamp);

    if (timestamp == null) {
      return [];
    }

    final age = DateTime.now().millisecondsSinceEpoch - (timestamp as int);

    if (age > _profilePostsCacheDuration.inMilliseconds) {
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
        } catch (_) {
          // Intentionally ignored.
        }
      }

      return posts;
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearSavedPostsCache() async {
    await _savedPostsBox.clear();
  }

  // ------------------------------------------------------------
  // CLEAR BOTH PROFILE POST CACHES
  // ------------------------------------------------------------

  static Future<void> clearProfilePostsCache() async {
    await _myPostsBox.clear();
    await _savedPostsBox.clear();
  }

  static Future<void> clearUserData() async {
    // Home feed
    await clearPostCache();

    // User profile
    await clearUserProfileCache();

    // Following IDs
    await clearFollowingCache();

    // My posts
    try {
      await Hive.box(HiveBoxes.cachedMyPosts).clear();
    } catch (_) {
      // Intentionally ignored.
    }

    // Saved posts
    try {
      await Hive.box(HiveBoxes.cachedSavedPosts).clear();
    } catch (_) {
      // Intentionally ignored.
    }

    // Followers / Following
    try {
      await Hive.box(HiveBoxes.cachedFollowersFollowing).clear();
    } catch (_) {
      // Intentionally ignored.
    }
  }

  // ============================================================
  // OTHER USER PROFILE CACHE
  // ============================================================

  static String _profileCacheKey(String userId) {
    return 'profile_$userId';
  }

  static String _profileTimestampKey(String userId) {
    return 'profile_${userId}_timestamp';
  }

  static ProfileModel? getCachedProfileByUserId(String userId) {
    final key = _profileCacheKey(userId);

    final data = _profileBox.get(key);

    if (data == null) {
      return null;
    }

    final timestamp = _profileBox.get(_profileTimestampKey(userId));

    if (timestamp == null) {
      _profileBox.delete(key);

      return null;
    }

    final age = DateTime.now().millisecondsSinceEpoch - (timestamp as int);

    if (age > _profileCacheDuration.inMilliseconds) {
      clearCachedProfileByUserId(userId);

      return null;
    }

    try {
      return ProfileModel.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  static Future<void> cacheProfileByUserId(ProfileModel profile) async {
    final userId = profile.id;

    await _profileBox.put(_profileCacheKey(userId), profile.toJson());

    await _profileBox.put(
      _profileTimestampKey(userId),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> clearCachedProfileByUserId(String userId) async {
    await _profileBox.delete(_profileCacheKey(userId));

    await _profileBox.delete(_profileTimestampKey(userId));
  }

  static Future<void> clearAllCachedProfiles() async {
    await _profileBox.clear();
  }
}
