import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:public_pulse/model/profile_model.dart';
import 'package:public_pulse/core/repository/profile_repository.dart';

class FollowersFollowingController extends GetxController {
  static FollowersFollowingController get to => Get.find();

  final ProfileRepository _repo = ProfileRepository.instance;

  final String userId;

  FollowersFollowingController({
    required this.userId,
  });

  // ─────────────────────────────────────────────────────────────
  // Pagination
  // ─────────────────────────────────────────────────────────────
  //
  // The repository fetches the *entire* followers/following list in one
  // round-trip (there's no cursor/limit param on the backend), so paging is
  // done client-side over the already-fetched list rather than re-hitting
  // the network.

  static const int pageSize = 20;

  final currentFollowersPage = 0.obs;
  final currentFollowingPage = 0.obs;

  List<FollowerModel> _pageOf(List<FollowerModel> source, int page) {
    final start = page * pageSize;
    if (start >= source.length) return const [];
    final end = (start + pageSize).clamp(0, source.length);
    return source.sublist(start, end);
  }

  List<FollowerModel> get pagedFollowers =>
      _pageOf(followers, currentFollowersPage.value);

  List<FollowerModel> get pagedFollowing =>
      _pageOf(following, currentFollowingPage.value);

  bool get hasPrevFollowers => currentFollowersPage.value > 0;

  bool get hasNextFollowers =>
      (currentFollowersPage.value + 1) * pageSize < followers.length;

  bool get hasPrevFollowing => currentFollowingPage.value > 0;

  bool get hasNextFollowing =>
      (currentFollowingPage.value + 1) * pageSize < following.length;

  void nextPage({required bool isFollowers}) {
    if (isFollowers) {
      if (hasNextFollowers) currentFollowersPage.value++;
    } else {
      if (hasNextFollowing) currentFollowingPage.value++;
    }
  }

  void prevPage({required bool isFollowers}) {
    if (isFollowers) {
      if (hasPrevFollowers) currentFollowersPage.value--;
    } else {
      if (hasPrevFollowing) currentFollowingPage.value--;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Tab
  // ─────────────────────────────────────────────────────────────

  final selectedTab = 0.obs;

  void switchTab(int index) {
    debugPrint('[FF_DEBUG] switchTab: $index');

    selectedTab.value = index;

    if (index == 0 && followers.isEmpty) {
      loadFollowers();
    }

    if (index == 1 && following.isEmpty) {
      loadFollowing();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Followers
  // ─────────────────────────────────────────────────────────────

  final RxList<FollowerModel> followers =
      <FollowerModel>[].obs;

  final isLoadingFollowers = false.obs;

  // ─────────────────────────────────────────────────────────────
  // Following
  // ─────────────────────────────────────────────────────────────

  final RxList<FollowerModel> following =
      <FollowerModel>[].obs;

  final isLoadingFollowing = false.obs;

  // ─────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    debugPrint(
      '[FF_DEBUG] Controller initialized for user: $userId',
    );

    loadFollowers();
  }

  // ─────────────────────────────────────────────────────────────
  // Load followers
  // ─────────────────────────────────────────────────────────────

  Future<void> loadFollowers() async {
    if (isLoadingFollowers.value) return;

    debugPrint('[FF_DEBUG] Loading followers...');

    isLoadingFollowers(true);

    try {
      final result = await _repo.getFollowers(userId);

      debugPrint(
        '[FF_DEBUG] Followers received: ${result.length}',
      );

      followers.assignAll(result);
      currentFollowersPage.value = 0;

      debugPrint(
        '[FF_DEBUG] Followers list now: ${followers.length}',
      );
    } catch (e, stack) {
      debugPrint('[FF_DEBUG] Followers error: $e');
      debugPrint('$stack');
    } finally {
      isLoadingFollowers(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Load following
  // ─────────────────────────────────────────────────────────────

  Future<void> loadFollowing() async {
    if (isLoadingFollowing.value) return;

    debugPrint('[FF_DEBUG] Loading following...');

    isLoadingFollowing(true);

    try {
      final result = await _repo.getFollowing(userId);

      debugPrint(
        '[FF_DEBUG] Following received: ${result.length}',
      );

      following.assignAll(result);
      currentFollowingPage.value = 0;

      debugPrint(
        '[FF_DEBUG] Following list now: ${following.length}',
      );
    } catch (e, stack) {
      debugPrint('[FF_DEBUG] Following error: $e');
      debugPrint('$stack');
    } finally {
      isLoadingFollowing(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Cache invalidation
  // ─────────────────────────────────────────────────────────────

  /// Clears the cached followers/following lists (and resets pagination)
  /// without re-fetching. The next [switchTab] call will see an empty list
  /// and trigger a fresh load. Use this after a follow/unfollow action
  /// elsewhere in the app so this controller doesn't show stale data next
  /// time its page is opened.
  void invalidateCache() {
    followers.clear();
    following.clear();
    currentFollowersPage.value = 0;
    currentFollowingPage.value = 0;

    debugPrint('[FF_DEBUG] Cache invalidated');
  }

  // ─────────────────────────────────────────────────────────────
  // Refresh
  // ─────────────────────────────────────────────────────────────

  Future<void> refreshList() async {
    followers.clear();
    following.clear();
    currentFollowersPage.value = 0;
    currentFollowingPage.value = 0;

    if (selectedTab.value == 0) {
      await loadFollowers();
    } else {
      await loadFollowing();
    }
  }
}