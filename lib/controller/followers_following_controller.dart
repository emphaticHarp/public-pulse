import 'package:get/get.dart';
import 'package:public_pulse/model/profile_model.dart';
import 'package:public_pulse/core/repository/profile_repository.dart';
import 'package:public_pulse/core/cache/followers_following_cache.dart';

class FollowersFollowingController extends GetxController {
  static FollowersFollowingController get to => Get.find();

  final ProfileRepository _repo = ProfileRepository.instance;

  final FollowersFollowingCacheService _cache =
      FollowersFollowingCacheService();

  final String userId;

  FollowersFollowingController({required this.userId});

  // ─────────────────────────────────────────────
  // TAB
  // ─────────────────────────────────────────────

  final selectedTab = 0.obs;

  // ─────────────────────────────────────────────
  // FOLLOWERS
  // ─────────────────────────────────────────────

  final RxList<FollowerModel> followers = <FollowerModel>[].obs;

  final isLoadingFollowers = false.obs;

  bool _followersLoaded = false;

  // ─────────────────────────────────────────────
  // FOLLOWING
  // ─────────────────────────────────────────────

  final RxList<FollowerModel> following = <FollowerModel>[].obs;

  final isLoadingFollowing = false.obs;

  bool _followingLoaded = false;

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    print('[FF_DEBUG] Controller initialized');
    print('[FF_DEBUG] userId: $userId');

    loadFollowers();
  }

  // ─────────────────────────────────────────────
  // TAB SWITCH
  // ─────────────────────────────────────────────

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

  // ─────────────────────────────────────────────
  // LOAD FOLLOWERS
  // ─────────────────────────────────────────────

  Future<void> loadFollowers() async {
    if (isLoadingFollowers.value) {
      return;
    }

    print('[FF_DEBUG] Loading followers...');
    print('[FF_DEBUG] Profile userId: $userId');

    // 1. Try cache first
    final cached = _cache.get(userId);

    if (cached != null) {
      final cachedFollowers = cached['followers'] ?? [];

      followers.assignAll(cachedFollowers);
      _followersLoaded = true;

      print('[FF_CACHE] Loaded ${followers.length} followers from cache');
    }

    // 2. Fetch latest data from Supabase
    isLoadingFollowers(true);

    try {
      final result = await _repo.getFollowers(userId);

      print('[FF_DEBUG] Repository returned ${result.length} followers');

      followers.assignAll(result);
      _followersLoaded = true;

      // 3. Save latest data
      await _cache.updateFollowers(
        profileId: userId,
        followers: followers.cast(),
      );
      print('[FF_CACHE] Saved ${followers.length} followers to cache');
    } catch (e, stackTrace) {
      print('[FF_DEBUG] ERROR loading followers: $e');
      print(stackTrace);
    } finally {
      isLoadingFollowers(false);
    }
  }

  // ─────────────────────────────────────────────
  // LOAD FOLLOWING
  // ─────────────────────────────────────────────

  Future<void> loadFollowing() async {
    if (isLoadingFollowing.value) {
      return;
    }

    print('[FF_DEBUG] Loading following...');
    print('[FF_DEBUG] Profile userId: $userId');

    // 1. Try cache first
    final cached = _cache.get(userId);

    if (cached != null) {
      final cachedFollowing = cached['following'] ?? [];

      following.assignAll(cachedFollowing);
      _followingLoaded = true;

      print('[FF_CACHE] Loaded ${following.length} following from cache');
    }

    // 2. Fetch latest data
    isLoadingFollowing(true);

    try {
      final result = await _repo.getFollowing(userId);

      print('[FF_DEBUG] Repository returned ${result.length} following');

      following.assignAll(result);
      _followingLoaded = true;

      // 3. Save latest data
      await _cache.updateFollowing(
        profileId: userId,
        following: following.cast(),
      );
      print('[FF_CACHE] Saved ${following.length} following to cache');
    } catch (e, stackTrace) {
      print('[FF_DEBUG] ERROR loading following: $e');
      print(stackTrace);
    } finally {
      isLoadingFollowing(false);
    }
  }

  // ─────────────────────────────────────────────
  // REFRESH
  // ─────────────────────────────────────────────

  Future<void> refreshList() async {
    print('[FF_DEBUG] Refreshing followers/following');

    _followersLoaded = false;
    _followingLoaded = false;

    followers.clear();
    following.clear();

    if (selectedTab.value == 0) {
      await loadFollowers();
    } else {
      await loadFollowing();
    }
  }

  // ─────────────────────────────────────────────
  // INVALIDATE
  // ─────────────────────────────────────────────

  void invalidateCache() {
    _followersLoaded = false;
    _followingLoaded = false;

    followers.clear();
    following.clear();
  }
}
