import 'package:hive_ce_flutter/hive_flutter.dart';
import 'hive_boxes.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    await Hive.openBox(HiveBoxes.cachedPosts);
    await Hive.openBox(HiveBoxes.cachedProfiles);
    await Hive.openBox(HiveBoxes.cachedComments);

    await Hive.openBox(HiveBoxes.recentSearches);

    await Hive.openBox(HiveBoxes.cachedFollowing);

    await Hive.openBox(HiveBoxes.cachedFollowersFollowing);

    await Hive.openBox(HiveBoxes.cachedUserProfile);
  }
}
