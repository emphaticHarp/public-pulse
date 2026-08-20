import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:public_pulse/model/recent_search_model.dart';

import 'cache_keys.dart';
import 'hive_boxes.dart';

class RecentSearchCache {
  static Box get _box => Hive.box(HiveBoxes.recentSearches);

  static List<RecentSearchModel> getSearches() {
    final List data = _box.get(
      CacheKeys.recentSearches,
      defaultValue: <Map<String, dynamic>>[],
    );

    return data
        .map((e) => RecentSearchModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> addSearch(RecentSearchModel profile) async {
    final searches = getSearches();

    searches.removeWhere((e) => e.userId == profile.userId);

    searches.insert(0, profile);

    if (searches.length > 10) {
      searches.removeLast();
    }

    await _box.put(
      CacheKeys.recentSearches,
      searches.map((e) => e.toJson()).toList(),
    );
  }

  static Future<void> removeSearch(RecentSearchModel profile) async {
    final searches = getSearches();

    searches.removeWhere((e) => e.userId == profile.userId);

    await _box.put(
      CacheKeys.recentSearches,
      searches.map((e) => e.toJson()).toList(),
    );
  }

  static Future<void> clearAll() async {
    await _box.put(CacheKeys.recentSearches, <Map<String, dynamic>>[]);
  }
}
