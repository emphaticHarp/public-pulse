import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:public_pulse/model/post_model.dart';
import 'hive_boxes.dart';

class CacheManager {
  // Posts remain valid for 5 days before being considered expired.
  static const Duration postCacheTTL = Duration(days: 5);

  // Hive box for cached posts.
  static Box get _postBox => Hive.box(HiveBoxes.cachedPosts);

  // Save posts and the current timestamp.
  static Future<void> cachePosts(List<PostModel> posts) async {
    debugPrint('[DEBUG-CACHE] cachePosts: Saving ${posts.length} posts to Hive');
    debugPrint('[DEBUG-CACHE] cachePosts: Post IDs: ${posts.map((e) => e.id).toList()}');
    
    final postsJson = posts.map((e) => e.toJson()).toList();
    debugPrint('[DEBUG-CACHE] cachePosts: JSON count = ${postsJson.length}');
    
    await _postBox.put('posts', postsJson);
    await _postBox.put('timestamp', DateTime.now().millisecondsSinceEpoch);
    
    // Verify the save
    final savedPosts = _postBox.get('posts');
    debugPrint('[DEBUG-CACHE] cachePosts: Verified saved count = ${savedPosts?.length ?? 0}');
  }

  // Load cached posts if available.
  static List<PostModel> getCachedPosts() {
    debugPrint('[DEBUG-CACHE] getCachedPosts: Starting...');
    
    final cached = _postBox.get('posts');
    
    if (cached == null) {
      debugPrint('[DEBUG-CACHE] getCachedPosts: cached is NULL, returning empty list');
      return [];
    }
    
    debugPrint('[DEBUG-CACHE] getCachedPosts: cached raw length = ${(cached as List).length}');
    
    final List<PostModel> posts = [];
    for (int i = 0; i < cached.length; i++) {
      try {
        final postData = Map<String, dynamic>.from(cached[i]);
        debugPrint('[DEBUG-CACHE] getCachedPosts: Parsing post $i, id=${postData['id']}');
        final post = PostModel.fromCache(postData);
        posts.add(post);
        debugPrint('[DEBUG-CACHE] getCachedPosts: Successfully parsed post $i: id=${post.id}, mediaUrls=${post.mediaUrls.length}');
      } catch (e) {
        debugPrint('[DEBUG-CACHE] getCachedPosts: ERROR parsing post $i: $e');
      }
    }
    
    debugPrint('[DEBUG-CACHE] getCachedPosts: Returning ${posts.length} posts');
    return posts;
  }

  // Check whether the cache has expired.
  static bool isPostCacheExpired() {
    debugPrint('[DEBUG-CACHE] isPostCacheExpired: Checking...');
    
    final timestamp = _postBox.get('timestamp');

    if (timestamp == null) {
      debugPrint('[DEBUG-CACHE] isPostCacheExpired: timestamp is NULL, cache is EXPIRED');
      return true;
    }

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cachedTime);
    final isExpired = difference > postCacheTTL;
    
    debugPrint('[DEBUG-CACHE] isPostCacheExpired: timestamp=$timestamp, cachedTime=$cachedTime, now=$now');
    debugPrint('[DEBUG-CACHE] isPostCacheExpired: difference=$difference, TTL=$postCacheTTL, isExpired=$isExpired');
    
    return isExpired;
  }

  // Remove all cached posts.
  static Future<void> clearPostCache() async {
    debugPrint('[DEBUG-CACHE] clearPostCache: Clearing all cached posts');
    await _postBox.clear();
    debugPrint('[DEBUG-CACHE] clearPostCache: Cache cleared');
  }
}
