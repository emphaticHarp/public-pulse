import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:public_pulse/model/post_model.dart';
import 'package:public_pulse/model/comment_model.dart';

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
}
