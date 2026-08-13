import 'package:get/get.dart';

import '../model/profile_model.dart';
import '../core/repository/user_profile_repository.dart';

import 'followers_following_controller.dart';
import '../view/profile/followers_following_page.dart';

class UserProfileController extends GetxController {
  final String userId;

  UserProfileController({required this.userId});

  final UserProfileRepository _repo = UserProfileRepository.instance;

  // ─────────────────────────────────────────────
  // FOLLOWERS / FOLLOWING CONTROLLER TAG
  // ─────────────────────────────────────────────

  late final String ffTag = 'user_$userId';

  // ─────────────────────────────────────────────
  // PROFILE
  // ─────────────────────────────────────────────

  final profile = Rxn<ProfileModel>();

  final isLoading = false.obs;

  // ─────────────────────────────────────────────
  // FOLLOW STATE
  // ─────────────────────────────────────────────

  /// Me → target
  final isFollowing = false.obs;

  /// Target → me
  final followsMe = false.obs;

  final isFollowLoading = false.obs;

  // ─────────────────────────────────────────────
  // COUNTS
  // ─────────────────────────────────────────────

  final followerCount = 0.obs;

  final followingCount = 0.obs;

  // ─────────────────────────────────────────────
  // TABS
  // ─────────────────────────────────────────────

  final selectedTab = ProfileTab.photos.obs;

  // ─────────────────────────────────────────────
  // MEDIA
  // ─────────────────────────────────────────────

  final photoPosts = <String>[].obs;

  // ─────────────────────────────────────────────
  // URL CACHE
  // ─────────────────────────────────────────────

  String? avatarUrl;

  String? coverUrl;

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    _loadProfile();
  }

  // ─────────────────────────────────────────────
  // LOAD PROFILE
  // ─────────────────────────────────────────────

  Future<void> _loadProfile() async {
    isLoading(true);

    try {
      final profileFuture = _repo.getUserProfile(userId);

      final followingFuture = _repo.isFollowing(userId);

      final followsMeFuture = _repo.isFollowedBy(userId);

      final postsFuture = _repo.getUserPostImages(userId);

      // Run all requests in parallel.
      final loadedProfile = await profileFuture;

      final following = await followingFuture;

      final followedByMe = await followsMeFuture;

      final loadedPosts = await postsFuture;

      // Resolve URLs once.
      avatarUrl = loadedProfile.avatarPath != null
          ? _repo.resolveUrl(loadedProfile.avatarPath!, bucket: 'avatars')
          : null;

      coverUrl = loadedProfile.coverPath != null
          ? _repo.resolveUrl(loadedProfile.coverPath!, bucket: 'covers')
          : null;

      profile.value = loadedProfile;

      photoPosts.assignAll(loadedPosts);

      followerCount.value = loadedProfile.followerCount ?? 0;

      followingCount.value = loadedProfile.followingCount ?? 0;

      isFollowing.value = following;

      followsMe.value = followedByMe;
    } catch (e) {
      print('[USER_PROFILE] ERROR: $e');
    } finally {
      isLoading(false);
    }
  }

  // ─────────────────────────────────────────────
  // BUTTON LABEL
  // ─────────────────────────────────────────────

  String get followButtonLabel {
    if (isFollowing.value) {
      return 'Following';
    }

    if (followsMe.value) {
      return 'Follow Back';
    }

    return 'Follow';
  }

  // ─────────────────────────────────────────────
  // TOGGLE FOLLOW
  // ─────────────────────────────────────────────

  Future<void> toggleFollow() async {
    if (isFollowLoading.value) {
      return;
    }

    isFollowLoading(true);

    final wasFollowing = isFollowing.value;

    final oldFollowerCount = followerCount.value;

    // ─────────────────────────────────────────
    // OPTIMISTIC UI
    // ─────────────────────────────────────────

    isFollowing.value = !wasFollowing;

    followerCount.value = wasFollowing
        ? (followerCount.value - 1).clamp(0, 999999999)
        : followerCount.value + 1;

    try {
      if (wasFollowing) {
        await _repo.unfollowUser(userId);
      } else {
        await _repo.followUser(userId);
      }
    } catch (e) {
      print('[USER_PROFILE] FOLLOW ERROR: $e');

      // Rollback.
      isFollowing.value = wasFollowing;

      followerCount.value = oldFollowerCount;
    } finally {
      isFollowLoading(false);
    }
  }

  // ─────────────────────────────────────────────
  // TAB
  // ─────────────────────────────────────────────

  void changeTab(ProfileTab tab) {
    selectedTab.value = tab;
  }

  // ─────────────────────────────────────────────
  // FOLLOWERS / FOLLOWING PAGE
  // ─────────────────────────────────────────────

  void openFollowersFollowing(int initialTab) {
    if (!Get.isRegistered<FollowersFollowingController>(tag: ffTag)) {
      Get.put(FollowersFollowingController(userId: userId), tag: ffTag);
    }

    final controller = Get.find<FollowersFollowingController>(tag: ffTag);

    controller.switchTab(initialTab);

    Get.to(
      () =>
          FollowersFollowingPage(initialTab: initialTab, controllerTag: ffTag),
    );
  }
}
