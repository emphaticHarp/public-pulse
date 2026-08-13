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

    print('[FF_DEBUG] Controller initialized');
    print('[FF_DEBUG] userId: $userId');
    print('[FF_DEBUG] initialTab: $initialTab');

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
    print('[FF_DEBUG] switchTab: $index');

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

    print('[FF_DEBUG] Loading followers...');
    print('[FF_DEBUG] Profile userId: $userId');
    print('[FF_DEBUG] forceRefresh: $forceRefresh');

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

            print('[FF_CACHE] Loaded ${followers.length} followers from cache');
          }
        }
      } catch (e, stackTrace) {
        print('[FF_CACHE] ERROR reading followers cache: $e');
        print(stackTrace);
      }
    }

    // ----------------------------------------------------------
    // SUPABASE
    // ----------------------------------------------------------

    isLoadingFollowers(true);

    try {
      final result = await _repo.getFollowers(userId);

      print('[FF_DEBUG] Repository returned ${result.length} followers');

      followers.assignAll(result);

      _followersLoaded = true;

      await _cache.updateFollowers(profileId: userId, followers: result);

      print('[FF_CACHE] Saved ${result.length} followers to cache');
    } catch (e, stackTrace) {
      print('[FF_DEBUG] ERROR loading followers: $e');
      print(stackTrace);

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

    print('[FF_DEBUG] Loading following...');
    print('[FF_DEBUG] Profile userId: $userId');
    print('[FF_DEBUG] forceRefresh: $forceRefresh');

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

            print('[FF_CACHE] Loaded ${following.length} following from cache');
          }
        }
      } catch (e, stackTrace) {
        print('[FF_CACHE] ERROR reading following cache: $e');
        print(stackTrace);
      }
    }

    // ----------------------------------------------------------
    // SUPABASE
    // ----------------------------------------------------------

    isLoadingFollowing(true);

    try {
      final result = await _repo.getFollowing(userId);

      print('[FF_DEBUG] Repository returned ${result.length} following');

      following.assignAll(result);

      _followingLoaded = true;

      await _cache.updateFollowing(profileId: userId, following: result);

      print('[FF_CACHE] Saved ${result.length} following to cache');
    } catch (e, stackTrace) {
      print('[FF_DEBUG] ERROR loading following: $e');
      print(stackTrace);

      // Keep cached/current users visible.
    } finally {
      isLoadingFollowing(false);
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshList() async {
    print('[FF_DEBUG] Refreshing current list');

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
