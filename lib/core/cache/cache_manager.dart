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
    await _postBox.put('posts', posts.map((e) => e.toJson()).toList());

    await _postBox.put('timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  // Load cached posts if available.
  static List<PostModel> getCachedPosts() {
    final cached = _postBox.get('posts');

    if (cached == null) {
      return [];
    }

    return (cached as List)
        .map((e) => PostModel.fromCache(Map<String, dynamic>.from(e)))
        .toList();
  }

  // Check whether the cache has expired.
  static bool isPostCacheExpired() {
    final timestamp = _postBox.get('timestamp');

    if (timestamp == null) {
      return true;
    }

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    return DateTime.now().difference(cachedTime) > postCacheTTL;
  }

  // Remove all cached posts.
  static Future<void> clearPostCache() async {
    await _postBox.clear();
  }
}
