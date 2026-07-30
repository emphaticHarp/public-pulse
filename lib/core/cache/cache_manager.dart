import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:public_pulse/model/post_model.dart';
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
    debugPrint(
      '[DEBUG-CACHE] cachePosts: Saving ${posts.length} posts to Hive',
    );
    debugPrint(
      '[DEBUG-CACHE] cachePosts: Post IDs: ${posts.map((e) => e.id).toList()}',
    );

    final postsJson = posts.map((e) => e.toJson()).toList();
    debugPrint('[DEBUG-CACHE] cachePosts: JSON count = ${postsJson.length}');

    await _postBox.put(CacheKeys.posts, postsJson);
    await _postBox.put(
      CacheKeys.timestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
    await _postBox.put(CacheKeys.nextCursor, nextCursor);
    await _postBox.put(CacheKeys.hasMore, hasMore);

    // Verify the save
    final savedPosts = _postBox.get(CacheKeys.posts);
    debugPrint(
      '[DEBUG-CACHE] cachePosts: Verified saved count = ${savedPosts?.length ?? 0}',
    );
  }

  // Load cached posts if available.
  static List<PostModel> getCachedPosts() {
    debugPrint('[DEBUG-CACHE] getCachedPosts: Starting...');

    final cached = _postBox.get(CacheKeys.posts);

    if (cached == null) {
      debugPrint(
        '[DEBUG-CACHE] getCachedPosts: cached is NULL, returning empty list',
      );
      return [];
    }

    debugPrint(
      '[DEBUG-CACHE] getCachedPosts: cached raw length = ${(cached as List).length}',
    );

    final List<PostModel> posts = [];
    for (int i = 0; i < cached.length; i++) {
      try {
        final postData = Map<String, dynamic>.from(cached[i]);
        debugPrint(
          '[DEBUG-CACHE] getCachedPosts: Parsing post $i, id=${postData['id']}',
        );
        final post = PostModel.fromCache(postData);
        posts.add(post);
        debugPrint(
          '[DEBUG-CACHE] getCachedPosts: Successfully parsed post $i: id=${post.id}, mediaUrls=${post.mediaUrls.length}',
        );
      } catch (e) {
        debugPrint('[DEBUG-CACHE] getCachedPosts: ERROR parsing post $i: $e');
      }
    }

    debugPrint('[DEBUG-CACHE] getCachedPosts: Returning ${posts.length} posts');
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
    debugPrint('[DEBUG-CACHE] clearPostCache: Clearing all cached posts');
    await _postBox.clear();
    debugPrint('[DEBUG-CACHE] clearPostCache: Cache cleared');
  }
}
