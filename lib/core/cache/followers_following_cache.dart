import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:public_pulse/model/profile_model.dart';
import 'hive_boxes.dart';

class FollowersFollowingCacheService {
  static const Duration cacheDuration = Duration(days: 5);

  Box get _box => Hive.box(HiveBoxes.cachedFollowersFollowing);

  // ─────────────────────────────────────────────
  // SAVE
  // ─────────────────────────────────────────────

  Future<void> save({
    required String profileId,
    required List<FollowerModel> followers,
    required List<FollowerModel> following,
  }) async {
    await _box.put(profileId, {
      'cachedAt': DateTime.now().toIso8601String(),

      'followers': followers.map((user) {
        return {
          'userId': user.userId,
          'username': user.username,
          'displayName': user.displayName,
          'avatarPath': user.avatarPath,
        };
      }).toList(),

      'following': following.map((user) {
        return {
          'userId': user.userId,
          'username': user.username,
          'displayName': user.displayName,
          'avatarPath': user.avatarPath,
        };
      }).toList(),
    });
  }

  Future updateFollowers({
    required String profileId,
    required List followers,
  }) async {
    final existing = _box.get(profileId);

    final existingMap = existing != null
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{};

    final existingFollowing = (existingMap['following'] as List?) ?? [];

    await _box.put(profileId, {
      'cachedAt': DateTime.now().toIso8601String(),

      'followers': followers.map((user) {
        return {
          'userId': user.userId,
          'username': user.username,
          'displayName': user.displayName,
          'avatarPath': user.avatarPath,
        };
      }).toList(),

      'following': existingFollowing,
    });
  }

  Future updateFollowing({
    required String profileId,
    required List following,
  }) async {
    final existing = _box.get(profileId);

    final existingMap = existing != null
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{};

    final existingFollowers = (existingMap['followers'] as List?) ?? [];

    await _box.put(profileId, {
      'cachedAt': DateTime.now().toIso8601String(),

      'followers': existingFollowers,

      'following': following.map((user) {
        return {
          'userId': user.userId,
          'username': user.username,
          'displayName': user.displayName,
          'avatarPath': user.avatarPath,
        };
      }).toList(),
    });
  }

  // ─────────────────────────────────────────────
  // LOAD
  // ─────────────────────────────────────────────

  Map<String, List<FollowerModel>>? get(String profileId) {
    final data = _box.get(profileId);

    if (data == null) {
      return null;
    }

    final map = Map<String, dynamic>.from(data);

    final cachedAt = DateTime.tryParse(map['cachedAt']?.toString() ?? '');

    if (cachedAt == null) {
      _box.delete(profileId);
      return null;
    }

    // ─────────────────────────────────────────
    // 5 DAY TTL
    // ─────────────────────────────────────────

    if (DateTime.now().difference(cachedAt) >= cacheDuration) {
      _box.delete(profileId);
      return null;
    }

    final followers = ((map['followers'] as List?) ?? [])
        .map(
          (item) => FollowerModel(
            userId: item['userId'] as String,
            username: item['username'] as String? ?? '',
            displayName: item['displayName'] as String?,
            avatarPath: item['avatarPath'] as String?,
          ),
        )
        .toList();

    final following = ((map['following'] as List?) ?? [])
        .map(
          (item) => FollowerModel(
            userId: item['userId'] as String,
            username: item['username'] as String? ?? '',
            displayName: item['displayName'] as String?,
            avatarPath: item['avatarPath'] as String?,
          ),
        )
        .toList();

    return {'followers': followers, 'following': following};
  }

  // ─────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────

  Future<void> delete(String profileId) async {
    await _box.delete(profileId);
  }

  // ─────────────────────────────────────────────
  // CLEAR ALL
  // ─────────────────────────────────────────────

  Future<void> clearAll() async {
    await _box.clear();
  }
}
