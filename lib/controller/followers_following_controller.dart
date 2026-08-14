import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:public_pulse/model/profile_model.dart';
import 'package:public_pulse/core/repository/profile_repository.dart';
import 'package:public_pulse/core/cache/followers_following_cache.dart';

class FollowersFollowingController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static FollowersFollowingController get to => Get.find();

  final ProfileRepository _repo = ProfileRepository.instance;

  final FollowersFollowingCacheService _cache =
      FollowersFollowingCacheService();

  final String userId;
  final int initialTab;

  FollowersFollowingController({required this.userId, this.initialTab = 0});

  // ============================================================
  // TAB
  // ============================================================

  final selectedTab = 0.obs;

  late final TabController tabController;

  // ============================================================
  // FOLLOWERS
  // ============================================================

  final RxList<FollowerModel> followers = <FollowerModel>[].obs;

  final isLoadingFollowers = false.obs;

  bool _followersLoaded = false;

  // ============================================================
  // FOLLOWING
  // ============================================================

  final RxList<FollowerModel> following = <FollowerModel>[].obs;

  final isLoadingFollowing = false.obs;

  bool _followingLoaded = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void onInit() {
    super.onInit();

    selectedTab.value = initialTab;

    tabController = TabController(
      length: 2,
      initialIndex: initialTab,
      vsync: this,
    );

    tabController.addListener(_handleTabChange);

    debugPrint('[FF_DEBUG] Controller initialized');
    debugPrint('[FF_DEBUG] userId: $userId');
    debugPrint('[FF_DEBUG] initialTab: $initialTab');

    if (initialTab == 0) {
      loadFollowers();
    } else {
      loadFollowing();
    }
  }

  // ============================================================
  // TAB LISTENER
  // ============================================================

  void _handleTabChange() {
    // This handles BOTH:
    // 1. tapping Followers / Following
    // 2. swiping TabBarView

    if (tabController.indexIsChanging) {
      return;
    }

    final index = tabController.index;

    if (selectedTab.value == index) {
      return;
    }

    switchTab(index);
  }

  // ============================================================
  // TAB SWITCH
  // ============================================================

  void switchTab(int index) {
    debugPrint('[FF_DEBUG] switchTab: $index');

    selectedTab.value = index;

    if (index == 0 && !_followersLoaded) {
      loadFollowers();
    }

    if (index == 1 && !_followingLoaded) {
      loadFollowing();
    }
  }

  // ============================================================
  // LOAD FOLLOWERS
  // ============================================================

  Future<void> loadFollowers({bool forceRefresh = false}) async {
    if (isLoadingFollowers.value) {
      return;
    }

    debugPrint('[FF_DEBUG] Loading followers...');
    debugPrint('[FF_DEBUG] Profile userId: $userId');
    debugPrint('[FF_DEBUG] forceRefresh: $forceRefresh');

    // ----------------------------------------------------------
    // CACHE FIRST
    // ----------------------------------------------------------

    if (!forceRefresh && followers.isEmpty) {
      try {
        final cached = _cache.get(userId);

        if (cached != null) {
          final cachedFollowers = cached['followers'] ?? <FollowerModel>[];

          if (cachedFollowers.isNotEmpty) {
            followers.assignAll(cachedFollowers);

            _followersLoaded = true;

            debugPrint('[FF_CACHE] Loaded ${followers.length} followers from cache');
          }
        }
      } catch (e, stackTrace) {
        debugPrint('[FF_CACHE] ERROR reading followers cache: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    // ----------------------------------------------------------
    // SUPABASE
    // ----------------------------------------------------------

    isLoadingFollowers(true);

    try {
      final result = await _repo.getFollowers(userId);

      debugPrint('[FF_DEBUG] Repository returned ${result.length} followers');

      followers.assignAll(result);

      _followersLoaded = true;

      await _cache.updateFollowers(profileId: userId, followers: result);

      debugPrint('[FF_CACHE] Saved ${result.length} followers to cache');
    } catch (e, stackTrace) {
      debugPrint('[FF_DEBUG] ERROR loading followers: $e');
      debugPrintStack(stackTrace: stackTrace);

      // Do NOT clear existing cached users.
    } finally {
      isLoadingFollowers(false);
    }
  }

  // ============================================================
  // LOAD FOLLOWING
  // ============================================================

  Future<void> loadFollowing({bool forceRefresh = false}) async {
    if (isLoadingFollowing.value) {
      return;
    }

    debugPrint('[FF_DEBUG] Loading following...');
    debugPrint('[FF_DEBUG] Profile userId: $userId');
    debugPrint('[FF_DEBUG] forceRefresh: $forceRefresh');

    // ----------------------------------------------------------
    // CACHE FIRST
    // ----------------------------------------------------------

    if (!forceRefresh && following.isEmpty) {
      try {
        final cached = _cache.get(userId);

        if (cached != null) {
          final cachedFollowing = cached['following'] ?? <FollowerModel>[];

          if (cachedFollowing.isNotEmpty) {
            following.assignAll(cachedFollowing);

            _followingLoaded = true;

            debugPrint('[FF_CACHE] Loaded ${following.length} following from cache');
          }
        }
      } catch (e, stackTrace) {
        debugPrint('[FF_CACHE] ERROR reading following cache: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    // ----------------------------------------------------------
    // SUPABASE
    // ----------------------------------------------------------

    isLoadingFollowing(true);

    try {
      final result = await _repo.getFollowing(userId);

      debugPrint('[FF_DEBUG] Repository returned ${result.length} following');

      following.assignAll(result);

      _followingLoaded = true;

      await _cache.updateFollowing(profileId: userId, following: result);

      debugPrint('[FF_CACHE] Saved ${result.length} following to cache');
    } catch (e, stackTrace) {
      debugPrint('[FF_DEBUG] ERROR loading following: $e');
      debugPrintStack(stackTrace: stackTrace);

      // Keep cached/current users visible.
    } finally {
      isLoadingFollowing(false);
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshList() async {
    debugPrint('[FF_DEBUG] Refreshing current list');

    // IMPORTANT:
    // Do not clear followers/following first.

    if (selectedTab.value == 0) {
      await loadFollowers(forceRefresh: true);
    } else {
      await loadFollowing(forceRefresh: true);
    }
  }

  // ============================================================
  // INVALIDATE
  // ============================================================

  void invalidateCache() {
    _followersLoaded = false;
    _followingLoaded = false;

    followers.clear();
    following.clear();
  }

  // ============================================================
  // CLOSE
  // ============================================================

  @override
  void onClose() {
    tabController.removeListener(_handleTabChange);
    tabController.dispose();

    super.onClose();
  }
}
