import 'package:get/get.dart';
import '../model/profile_model.dart';
import '../core/repository/user_profile_repository.dart';
import 'followers_following_controller.dart';
import '../view/profile/followers_following_page.dart';

/// Manages state for viewing another user's public profile.
class UserProfileController extends GetxController {
  final String userId;
  UserProfileController({required this.userId});

  final _repo = UserProfileRepository.instance;

  // Tag reused for both this controller and the scoped FollowersFollowingController.
  late final _ffTag = 'user_$userId';

  final profile = Rxn<ProfileModel>();
  final isLoading = false.obs;
  final isFollowing = false.obs;
  final isFollowLoading = false.obs;
  final followerCount = 0.obs;
  final followingCount = 0.obs;
  final selectedTab = ProfileTab.photos.obs;

  // Memoized public URLs — set once after profile loads; never recomputed per-get.
  String? avatarUrl;
  String? coverUrl;

  // Wire to PostRepository once the Posts feature exists.
  final photoPosts = <String>[].obs;
  final videoPosts = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }

  /// Loads the target user's profile (with follow counts) and follow status in parallel.
  Future<void> _loadProfile() async {
    isLoading(true);
    try {
      // getUserProfile already includes follower_count and following_count in
      // its SELECT, so no separate getFollowCounts round-trip is needed.
      final profileFuture = _repo.getUserProfile(userId);
      final followFuture = _repo.isFollowing(userId);

      final loadedProfile = await profileFuture;
      final following = await followFuture;

      // Memoize resolved URLs once so they are never recomputed per reactive read.
      avatarUrl = loadedProfile.avatarPath != null
          ? _repo.resolveUrl(loadedProfile.avatarPath!, bucket: 'avatars')
          : null;
      coverUrl = loadedProfile.coverPath != null
          ? _repo.resolveUrl(loadedProfile.coverPath!, bucket: 'covers')
          : null;

      profile.value = loadedProfile;
      followerCount.value = loadedProfile.followerCount ?? 0;
      followingCount.value = loadedProfile.followingCount ?? 0;
      isFollowing.value = following;
    } catch (_) {
      // Silently fail; the UI stays in the loading state without crashing.
    } finally {
      isLoading(false);
    }
  }

  /// Toggles the follow state optimistically, then syncs with the database.
  Future<void> toggleFollow() async {
    if (isFollowLoading.value) return;
    isFollowLoading(true);

    final wasFollowing = isFollowing.value;
    // Optimistic update: flip immediately for a snappy feel.
    isFollowing(!wasFollowing);
    followerCount.value += wasFollowing ? -1 : 1;

    try {
      if (wasFollowing) {
        await _repo.unfollowUser(userId);
      } else {
        await _repo.followUser(userId);
      }
    } catch (_) {
      // Revert on failure.
      isFollowing(wasFollowing);
      followerCount.value += wasFollowing ? 1 : -1;
    } finally {
      isFollowLoading(false);
    }
  }

  /// Changes the active content tab.
  void changeTab(ProfileTab tab) => selectedTab.value = tab;

  /// Opens the Followers/Following page for this user's profile.
  void openFollowersFollowing(int initialTab) {
    if (!Get.isRegistered<FollowersFollowingController>(tag: _ffTag)) {
      Get.put(FollowersFollowingController(userId: userId), tag: _ffTag);
    }
    Get.find<FollowersFollowingController>(tag: _ffTag).switchTab(initialTab);
    Get.to(() => FollowersFollowingPage(initialTab: initialTab));
  }
}
