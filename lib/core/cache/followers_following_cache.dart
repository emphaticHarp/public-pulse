import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:public_pulse/model/profile_model.dart';
import 'hive_boxes.dart';

class FollowersFollowingCacheService {
  static const Duration cacheDuration = Duration(minutes: 15);

  Box get _box => Hive.box(HiveBoxes.cachedFollowersFollowing);

  // ─────────────────────────────────────────────
  // SAVE
  // ─────────────────────────────────────────────

  Future<void> save({
    required String profileId,
    required List<FollowerModel> followers,
    required List<FollowerModel> following,
  }) async {
    final now = DateTime.now().toIso8601String();

    await _box.put(profileId, {
      'followersCachedAt': now,
      'followingCachedAt': now,

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

  Future<void> updateFollowers({
    required String profileId,
    required List<FollowerModel> followers,
  }) async {
    final existing = _box.get(profileId);

    final existingMap = existing != null
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{};

    final existingFollowing = (existingMap['following'] as List?) ?? [];

    await _box.put(profileId, {
      'followersCachedAt': DateTime.now().toIso8601String(),

      'followingCachedAt': existingMap['followingCachedAt'],

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

  Future<void> updateFollowing({
    required String profileId,
    required List<FollowerModel> following,
  }) async {
    final existing = _box.get(profileId);

    final existingMap = existing != null
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{};

    final existingFollowers = (existingMap['followers'] as List?) ?? [];

    await _box.put(profileId, {
      'followersCachedAt': existingMap['followersCachedAt'],

      'followingCachedAt': DateTime.now().toIso8601String(),

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

    try {
      final map = Map<String, dynamic>.from(data);

      final followersCachedAt = DateTime.tryParse(
        map['followersCachedAt']?.toString() ?? '',
      );

      final followingCachedAt = DateTime.tryParse(
        map['followingCachedAt']?.toString() ?? '',
      );

      final now = DateTime.now();

      // =========================================================
      // FOLLOWERS
      // =========================================================

      List<FollowerModel> followers = [];

      final followersValid =
          followersCachedAt != null &&
          now.difference(followersCachedAt) < cacheDuration;

      if (followersValid) {
        followers = ((map['followers'] as List?) ?? []).map((item) {
          final user = Map<String, dynamic>.from(item);

          return FollowerModel(
            userId: user['userId']?.toString() ?? '',
            username: user['username']?.toString() ?? '',
            displayName: user['displayName']?.toString(),
            avatarPath: user['avatarPath']?.toString(),
          );
        }).toList();
      }

      // =========================================================
      // FOLLOWING
      // =========================================================

      List<FollowerModel> following = [];

      final followingValid =
          followingCachedAt != null &&
          now.difference(followingCachedAt) < cacheDuration;

      if (followingValid) {
        following = ((map['following'] as List?) ?? []).map((item) {
          final user = Map<String, dynamic>.from(item);

          return FollowerModel(
            userId: user['userId']?.toString() ?? '',
            username: user['username']?.toString() ?? '',
            displayName: user['displayName']?.toString(),
            avatarPath: user['avatarPath']?.toString(),
          );
        }).toList();
      }

      if (!followersValid && !followingValid) {
        _box.delete(profileId);
        return null;
      }

      return {'followers': followers, 'following': following};
    } catch (_) {
      _box.delete(profileId);

      return null;
    }
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
