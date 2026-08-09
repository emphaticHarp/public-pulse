import 'package:get/get.dart';
import 'package:public_pulse/model/profile_model.dart';
import 'package:flutter/foundation.dart';
import 'package:public_pulse/core/repository/profile_repository.dart';
import 'package:public_pulse/controller/followers_following_controller.dart';
import 'package:public_pulse/view/profile/followers_following_page.dart';
import 'package:public_pulse/core/cache/cache_manager.dart';
import 'package:public_pulse/model/post_model.dart';
import 'package:public_pulse/core/repository/post_repository.dart';

class ProfileController extends GetxController {
  final PostRepository _postRepo = PostRepository();
  static ProfileController get to => Get.find();

  @override
  void onInit() {
    super.onInit();
    debugPrint("🔥 ProfileController Created");
    ensureProfileLoaded();
  }

  final ProfileRepository _repo = ProfileRepository.instance;

  final profile = Rxn<ProfileModel>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final selectedTab = ProfileTab.photos.obs;
  final postCount = 0.obs;
  final followerCount = 0.obs;
  final followingCount = 0.obs;

  //  wire to PostRepository once the Posts feature exists.
  final photoPosts = <PostModel>[].obs;
  final savedPosts = <PostModel>[].obs;

  final isPostsLoading = false.obs;
  final isSavedPostsLoading = false.obs;

  bool _profileLoaded = false;

  Future<void> ensureProfileLoaded() async {
    if (_profileLoaded) return;

    // --------------------------------------------------
    // 1. Load profile from Hive immediately
    // --------------------------------------------------

    final cachedProfile = CacheManager.getCachedUserProfile();
    if (cachedProfile != null) {
      debugPrint('[PROFILE] Loaded profile from Hive');
      debugPrint('[PROFILE] Cached user_id: ${cachedProfile.id}');

      profile.value = cachedProfile;

      followerCount.value = cachedProfile.followerCount ?? 0;
      followingCount.value = cachedProfile.followingCount ?? 0;

      postCount.value = cachedProfile.postCount ?? 0;

      await loadMyPosts();
      await loadSavedPosts();
    }

    // --------------------------------------------------
    // 2. No cache -> fetch from Supabase
    // --------------------------------------------------
    debugPrint('[PROFILE] No cache -> fetching from Supabase');

    isLoading.value = true;

    try {
      final fetchedProfile = await _repo.getProfile();

      final counts = await _repo.getFollowCounts(fetchedProfile.id);

      final profileWithCounts = ProfileModel(
        id: fetchedProfile.id,
        username: fetchedProfile.username,
        displayName: fetchedProfile.displayName,
        bio: fetchedProfile.bio,
        avatarPath: fetchedProfile.avatarPath,
        coverPath: fetchedProfile.coverPath,
        createdAt: fetchedProfile.createdAt,
        updatedAt: fetchedProfile.updatedAt,
        followerCount: counts.followers,
        followingCount: counts.following,
        postCount: fetchedProfile.postCount,
      );

      profile.value = profileWithCounts;

      followerCount.value = counts.followers;
      followingCount.value = counts.following;

      await CacheManager.cacheUserProfile(profileWithCounts);
      _profileLoaded = true;

      debugPrint('[PROFILE] Profile fetched and cached');

      await loadMyPosts();
      await loadSavedPosts();
    } catch (e, stackTrace) {
      _profileLoaded = false;

      errorMessage.value = 'Failed to load profile.';

      debugPrint('[PROFILE] Load error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProfile() async {
    final currentProfile = profile.value;

    if (currentProfile == null) {
      return;
    }

    debugPrint('[PROFILE] Pull-to-refresh started');

    try {
      final uid = currentProfile.id;

      // --------------------------------------------------
      // Fetch latest profile
      // --------------------------------------------------
      final updatedProfile = await _repo.getProfile();

      // --------------------------------------------------
      // Fetch latest follower/following counts
      // --------------------------------------------------
      final counts = await _repo.getFollowCounts(uid);

      // --------------------------------------------------
      // Create updated model with counts
      // --------------------------------------------------
      final profileWithCounts = ProfileModel(
        id: updatedProfile.id,
        username: updatedProfile.username,
        displayName: updatedProfile.displayName,
        bio: updatedProfile.bio,
        avatarPath: updatedProfile.avatarPath,
        coverPath: updatedProfile.coverPath,
        createdAt: updatedProfile.createdAt,
        updatedAt: updatedProfile.updatedAt,
        followerCount: counts.followers,
        followingCount: counts.following,
       postCount: updatedProfile.postCount,
      );

      // --------------------------------------------------
      // Update memory
      // --------------------------------------------------
      profile.value = profileWithCounts;

      followerCount.value = counts.followers;
      followingCount.value = counts.following;

      // --------------------------------------------------
      // Update Hive
      // --------------------------------------------------
      await CacheManager.cacheUserProfile(profileWithCounts);

      debugPrint('[PROFILE] Refresh complete → Hive updated');
    } catch (e, stackTrace) {
      debugPrint('[PROFILE] Refresh failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      errorMessage('Failed to refresh profile.');
    }
  }

  /// Resets in-memory cache so the next ensureProfileLoaded() re-fetches.
  Future<void> invalidateProfile() async {
    _profileLoaded = false;

    await CacheManager.clearUserProfileCache();

    debugPrint('[PROFILE CACHE] Invalidated');
  }

  void changeTab(ProfileTab tab) {
    selectedTab.value = tab;
  }

  Future<void> loadMyPosts() async {
    if (isPostsLoading.value) return;

    isPostsLoading(true);

    try {
      final result = await _postRepo.getMyPosts();

      photoPosts.assignAll(result);

      // Profiles table is the source of truth for post count.
      postCount.value = profile.value?.postCount ?? result.length;

      debugPrint('[PROFILE POSTS] Loaded ${photoPosts.length} posts');
    } catch (e, stackTrace) {
      debugPrint('[PROFILE POSTS] Error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isPostsLoading(false);
    }
  }

  Future<void> loadSavedPosts() async {
    if (isSavedPostsLoading.value) return;

    isSavedPostsLoading(true);

    try {
      final result = await _postRepo.getSavedPosts();

      savedPosts.assignAll(result);

      debugPrint('[PROFILE SAVED] Loaded ${savedPosts.length} saved posts');
    } catch (e, stackTrace) {
      debugPrint('[PROFILE SAVED] Error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isSavedPostsLoading(false);
    }
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
  Future<void> applyUpdatedProfile(ProfileModel updated) async {
    final old = profile.value;

    if (old?.avatarPath != null && old!.avatarPath != updated.avatarPath) {
      _repo.invalidateUrl(old.avatarPath!, bucket: 'avatars');
    }

    if (old?.coverPath != null && old!.coverPath != updated.coverPath) {
      _repo.invalidateUrl(old.coverPath!, bucket: 'covers');
    }

    // Keep existing counters.
    final updatedWithCounts = ProfileModel(
      id: updated.id,
      username: updated.username,
      displayName: updated.displayName,
      bio: updated.bio,
      avatarPath: updated.avatarPath,
      coverPath: updated.coverPath,
      createdAt: updated.createdAt,
      updatedAt: updated.updatedAt,
      followerCount: old?.followerCount ?? followerCount.value,
      followingCount: old?.followingCount ?? followingCount.value,
      postCount: old?.postCount ?? postCount.value,
    );

    // Update UI immediately.
    profile.value = updatedWithCounts;

    // Update counters.
    followerCount.value = updatedWithCounts.followerCount ?? 0;
    followingCount.value = updatedWithCounts.followingCount ?? 0;

    // Update Hive cache.
    await CacheManager.cacheUserProfile(updatedWithCounts);

    debugPrint('[PROFILE CACHE] Updated after profile edit');
  }

  /// Navigates to the Followers/Following page with the given initial tab.
  /// is viewed for the first time (or after an explicit invalidation).
  void openFollowersFollowing(int initialTab) {
    final currentProfile = profile.value;
    if (currentProfile == null) return;

    final uid = currentProfile.id;

    debugPrint('[PROFILE] Opening Followers/Following');
    debugPrint('[PROFILE] Profile user_id: $uid');

    if (!Get.isRegistered<FollowersFollowingController>()) {
      Get.put(FollowersFollowingController(userId: uid));
    }

    final ffController = FollowersFollowingController.to;

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
