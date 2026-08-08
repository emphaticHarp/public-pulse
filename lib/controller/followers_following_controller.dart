import 'package:get/get.dart';
import 'package:public_pulse/model/profile_model.dart';
import 'package:public_pulse/core/repository/profile_repository.dart';

class FollowersFollowingController extends GetxController {
  static FollowersFollowingController get to => Get.find();

  final ProfileRepository _repo = ProfileRepository.instance;

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
    print('[FF_DEBUG] Profile ID: $userId');

    isLoadingFollowers(true);

    try {
      final result = await _repo.getFollowers(userId);

      print('[FF_DEBUG] Repository returned ${result.length} followers');

      followers.assignAll(result);

      _followersLoaded = true;

      print('[FF_DEBUG] Followers list now contains ${followers.length}');
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
    print('[FF_DEBUG] Profile ID: $userId');

    isLoadingFollowing(true);

    try {
      final result = await _repo.getFollowing(userId);

      print('[FF_DEBUG] Repository returned ${result.length} following');

      following.assignAll(result);

      _followingLoaded = true;

      print('[FF_DEBUG] Following list now contains ${following.length}');
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
