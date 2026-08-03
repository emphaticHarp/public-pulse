import 'package:get/get.dart';
import '../model/profile_model.dart';
import '../core/repository/profile_repository.dart';
import 'followers_following_controller.dart';
import '../view/profile/followers_following_page.dart';

class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  final ProfileRepository _repo = ProfileRepository.instance;

  final profile = Rxn<ProfileModel>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final selectedTab = ProfileTab.photos.obs;
  final postCount = 0.obs;
  final followerCount = 0.obs;
  final followingCount = 0.obs;

  //  wire to PostRepository once the Posts feature exists.
  final photoPosts = <String>[].obs;
  final videoPosts = <String>[].obs;
  final savedPosts = <String>[].obs;

  bool _profileLoaded = false;

  /// Loads profile only on first request; returns immediately on cache hit.
  Future<void> ensureProfileLoaded() async {
    if (_profileLoaded) return;
    _profileLoaded = true;
    isLoading(true);
    try {
      profile.value = await _repo.getProfile();
      final uid = profile.value!.id;
      final counts = await _repo.getFollowCounts(uid);
      followerCount.value = counts.followers;
      followingCount.value = counts.following;
    } catch (e) {
      _profileLoaded = false;
      errorMessage('Failed to load profile.');
    } finally {
      isLoading(false);
    }
  }

  /// Resets in-memory cache so the next ensureProfileLoaded() re-fetches.
  void invalidateProfile() {
    _profileLoaded = false;
  }

  void changeTab(ProfileTab tab) {
    selectedTab.value = tab;
  }

  /// Path → URL conversion happens here so the UI never talks to Storage
  String? get avatarUrl => profile.value?.avatarPath != null
      ? _repo.resolveUrl(profile.value!.avatarPath!, bucket: 'avatars')
      : null;

  String? get coverUrl => profile.value?.coverPath != null
      ? _repo.resolveUrl(profile.value!.coverPath!, bucket: 'covers')
      : null;

  /// Called by [EditProfileController] after a successful save so the
  /// Profile screen refreshes automatically without a full reload.
  void applyUpdatedProfile(ProfileModel updated) {
    final old = profile.value;
    // Invalidate old image URLs when paths change after an upload.
    if (old?.avatarPath != null && old!.avatarPath != updated.avatarPath) {
      _repo.invalidateUrl(old.avatarPath!, bucket: 'avatars');
    }
    if (old?.coverPath != null && old!.coverPath != updated.coverPath) {
      _repo.invalidateUrl(old.coverPath!, bucket: 'covers');
    }
    profile.value = updated;
  }

  /// Navigates to the Followers/Following page with the given initial tab.
  /// is viewed for the first time (or after an explicit invalidation).
  void openFollowersFollowing(int initialTab) {
    final uid = profile.value?.id;
    if (uid == null) return;

    // Reuse the existing controller; create only on first visit.
    if (!Get.isRegistered<FollowersFollowingController>()) {
      Get.put(FollowersFollowingController(userId: uid));
    }

    final ffController = FollowersFollowingController.to;
    // switchTab is a no-op when the list is already cached.
    ffController.switchTab(initialTab);
    Get.to(() => FollowersFollowingPage(initialTab: initialTab));
  }

  /// Invalidates the followers/following cache (e.g. after a follow/unfollow
  /// action) so the next visit re-fetches fresh data from Supabase.
  void invalidateFollowersFollowing() {
    if (Get.isRegistered<FollowersFollowingController>()) {
      FollowersFollowingController.to.invalidateCache();
    }
    // Also refresh the counts shown on the profile page.
    _reloadCounts();
  }

  /// Re-fetches only the follower/following counts (lightweight, single round-trip).
  Future<void> _reloadCounts() async {
    final uid = profile.value?.id;
    if (uid == null) return;
    try {
      final counts = await _repo.getFollowCounts(uid);
      followerCount.value = counts.followers;
      followingCount.value = counts.following;
    } catch (_) {}
  }
}
