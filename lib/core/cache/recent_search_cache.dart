import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:public_pulse/model/profile_model.dart';

import 'cache_keys.dart';
import 'hive_boxes.dart';

class RecentSearchCache {
  static Box get _box => Hive.box(HiveBoxes.recentSearches);

  static List<ProfileModel> getSearches() {
    final List data = _box.get(
      CacheKeys.recentSearches,
      defaultValue: <Map<String, dynamic>>[],
    );

    return data
        .map((e) => ProfileModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> addSearch(ProfileModel profile) async {
    final searches = getSearches();

    searches.removeWhere((e) => e.id == profile.id);

    searches.insert(0, profile);

    if (searches.length > 10) {
      searches.removeLast();
    }

    await _box.put(
      CacheKeys.recentSearches,
      searches.map((e) => e.toJson()).toList(),
    );
  }

  static Future<void> removeSearch(ProfileModel profile) async {
    final searches = getSearches();

    searches.removeWhere((e) => e.id == profile.id);

    await _box.put(
      CacheKeys.recentSearches,
      searches.map((e) => e.toJson()).toList(),
    );
  }

  static Future<void> clearAll() async {
    await _box.put(CacheKeys.recentSearches, []);
  }
}