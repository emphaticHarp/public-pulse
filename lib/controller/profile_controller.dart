import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:public_pulse/model/profile_model.dart';
import 'package:public_pulse/model/post_model.dart';

import 'package:public_pulse/core/repository/profile_repository.dart';
import 'package:public_pulse/core/repository/post_repository.dart';
import 'package:public_pulse/core/cache/cache_manager.dart';

import 'package:public_pulse/controller/followers_following_controller.dart';
import 'package:public_pulse/view/profile/followers_following_page.dart';
import 'package:public_pulse/core/services/current_user_service.dart';

class ProfileController extends GetxController {
  ProfileController({this.userId});

  final String? userId;

  final ProfileRepository _repo = ProfileRepository.instance;
  final PostRepository _postRepo = PostRepository();

  /// This is only safe when the controller was registered without a tag.
  /// For tagged controllers, prefer:
  /// `Get.find<ProfileController>(tag: ...)`
  static ProfileController get to {
    return Get.find<ProfileController>();
  }

  bool get isMyProfile => userId == null;

  String get controllerTag => userId ?? 'my_profile';

  @override
  void onInit() {
    super.onInit();

    debugPrint('🔥 ProfileController Created');
    debugPrint('[PROFILE] userId = $userId');
    debugPrint('[PROFILE] isMyProfile = $isMyProfile');

    ensureProfileLoaded();
  }

  // ============================================================
  // STATE
  // ============================================================

  final profile = Rxn<ProfileModel>();

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final selectedTab = ProfileTab.photos.obs;

  final postCount = 0.obs;
  final followerCount = 0.obs;
  final followingCount = 0.obs;

  final photoPosts = <PostModel>[].obs;
  final savedPosts = <PostModel>[].obs;

  final isPostsLoading = false.obs;
  final isSavedPostsLoading = false.obs;

  bool _profileLoaded = false;

  // ============================================================
  // PROFILE LOAD
  // ============================================================

  Future<void> ensureProfileLoaded() async {
    if (_profileLoaded) return;

    errorMessage.value = '';

    if (isMyProfile) {
      await _loadMyProfile();
    } else {
      await _loadOtherProfile(userId!);
    }
  }

  // ============================================================
  // LOAD MY PROFILE
  // ============================================================

  Future<void> _loadMyProfile() async {
    // ----------------------------------------------------------
    // CACHE FIRST
    // ----------------------------------------------------------

    final cachedProfile = CacheManager.getCachedUserProfile();

    if (cachedProfile != null) {
      debugPrint('[PROFILE] Loaded own profile from Hive');
      debugPrint(
        '[PROFILE] Cached account status: ${cachedProfile.accountStatus}',
      );

      _applyProfileToState(cachedProfile);

      final cachedStatus =
          cachedProfile.accountStatus?.trim().toLowerCase();

      final hasValidStatus =
          cachedStatus != null &&
          cachedStatus.isNotEmpty &&
          cachedStatus != 'unknown';

      // Cache is complete, so use it normally.
      if (hasValidStatus) {
        _profileLoaded = true;

        await loadMyPosts();
        await loadSavedPosts();

        debugPrint(
          '[PROFILE] Own profile cache initialization complete',
        );

        return;
      }

      // Old/incomplete cache.
      // Continue below and refresh profile from Supabase.
      debugPrint(
        '[PROFILE] Cached profile missing valid status '
        '-> refreshing from Supabase',
      );
    }

    // ----------------------------------------------------------
    // SUPABASE
    // ----------------------------------------------------------

    debugPrint('[PROFILE] No own profile cache -> Supabase');

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
        accountStatus: fetchedProfile.accountStatus,
        referCode: fetchedProfile.referCode,
      );

      _applyProfileToState(profileWithCounts);

      await CacheManager.cacheUserProfile(profileWithCounts);

      _profileLoaded = true;

      debugPrint('[PROFILE] Own profile fetched + cached');

      await loadMyPosts();
      await loadSavedPosts();
    } catch (e, stackTrace) {
      _profileLoaded = false;

      errorMessage.value = 'Failed to load profile.';

      debugPrint('[PROFILE] Own profile load error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // LOAD OTHER USER PROFILE
  // ============================================================

  Future<void> _loadOtherProfile(String targetUserId) async {
    // ----------------------------------------------------------
    // CACHE FIRST
    // ----------------------------------------------------------

    final cachedProfile = CacheManager.getCachedProfileByUserId(targetUserId);

    if (cachedProfile != null) {
      debugPrint('[PROFILE] Loaded other profile from cache: $targetUserId');

      _applyProfileToState(cachedProfile);

      _profileLoaded = true;

      // Load latest posts.
      await loadUserPosts(targetUserId);

      debugPrint('[PROFILE] Other profile cache initialization complete');

      return;
    }

    // ----------------------------------------------------------
    // SUPABASE
    // ----------------------------------------------------------

    debugPrint('[PROFILE] No cached other profile -> fetching $targetUserId');

    isLoading.value = true;

    try {
      final fetchedProfile = await _repo.getProfileByProfileId(targetUserId);

      _applyProfileToState(fetchedProfile);

      await CacheManager.cacheProfileByUserId(fetchedProfile);

      _profileLoaded = true;

      await loadUserPosts(targetUserId);

      debugPrint('[PROFILE] Other profile fetched + cached: $targetUserId');
    } catch (e, stackTrace) {
      _profileLoaded = false;

      errorMessage.value = 'Failed to load profile.';

      debugPrint('[PROFILE] Other profile load error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // APPLY PROFILE TO MEMORY
  // ============================================================

  void _applyProfileToState(ProfileModel value) {
    profile.value = value;

    postCount.value = value.postCount ?? 0;
    followerCount.value = value.followerCount ?? 0;
    followingCount.value = value.followingCount ?? 0;
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshProfile() async {
    final currentProfile = profile.value;

    if (currentProfile == null) {
      await ensureProfileLoaded();
      return;
    }

    debugPrint('[PROFILE] Pull-to-refresh started | userId=$userId');

    try {
      final uid = currentProfile.id;

      // ============================================================
      // OTHER USER PROFILE
      // ============================================================

      if (userId != null) {
        final updatedProfile = await _repo.getProfileByProfileId(userId!);

        profile.value = updatedProfile;

        followerCount.value = updatedProfile.followerCount ?? 0;

        followingCount.value = updatedProfile.followingCount ?? 0;

        postCount.value = updatedProfile.postCount ?? 0;

        await CacheManager.cacheProfileByUserId(updatedProfile);

        await loadUserPosts(userId!);

        debugPrint('[PROFILE] Other profile refreshed: $userId');

        return;
      }

      // ============================================================
      // MY PROFILE
      // ============================================================

      final updatedProfile = await _repo.getProfile();

      final counts = await _repo.getFollowCounts(uid);

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
        accountStatus: updatedProfile.accountStatus,
        referCode: updatedProfile.referCode,
      );

      profile.value = profileWithCounts;

      followerCount.value = counts.followers;
      followingCount.value = counts.following;
      postCount.value = updatedProfile.postCount ?? 0;

      await CacheManager.cacheUserProfile(profileWithCounts);

      await loadMyPosts();
      await loadSavedPosts();

      debugPrint('[PROFILE] My profile refreshed');
    } catch (e, stackTrace) {
      debugPrint('[PROFILE] Refresh failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      errorMessage.value = 'Failed to refresh profile.';
    }
  }

  // ============================================================
  // INVALIDATE PROFILE
  // ============================================================

  Future<void> invalidateProfile() async {
    _profileLoaded = false;

    if (isMyProfile) {
      await CacheManager.clearUserProfileCache();
    } else {
      await CacheManager.clearCachedProfileByUserId(userId!);
    }

    profile.value = null;

    photoPosts.clear();
    savedPosts.clear();

    debugPrint('[PROFILE CACHE] Invalidated | userId=$userId');
  }

  // ============================================================
  // TABS
  // ============================================================

  void changeTab(ProfileTab tab) {
    selectedTab.value = tab;
  }

  // ============================================================
  // MY POSTS
  // ============================================================

  Future<void> loadMyPosts() async {
    if (isPostsLoading.value) return;

    // ----------------------------------------------------------
    // CACHE FIRST
    // ----------------------------------------------------------

    final cachedPosts = CacheManager.getCachedMyPosts();

    if (cachedPosts.isNotEmpty) {
      photoPosts.assignAll(cachedPosts);

      debugPrint(
        '[PROFILE POSTS] Loaded '
        '${photoPosts.length} posts from cache',
      );
    }

    // ----------------------------------------------------------
    // SERVER
    // ----------------------------------------------------------

    isPostsLoading.value = true;

    try {
      final result = await _postRepo.getMyPosts();

      photoPosts.assignAll(result);

      postCount.value = profile.value?.postCount ?? result.length;

      await CacheManager.cacheMyPosts(result);

      debugPrint(
        '[PROFILE POSTS] Server loaded '
        '${photoPosts.length} posts',
      );
    } catch (e, stackTrace) {
      debugPrint('[PROFILE POSTS] Error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isPostsLoading.value = false;
    }
  }

  // ============================================================
  // OTHER USER POSTS
  // ============================================================

  Future<void> loadUserPosts(String userId) async {
    if (isPostsLoading.value) return;

    isPostsLoading(true);

    try {
      final result = await _repo.getUserPostsByProfileId(userId);

      final currentProfileId = await CurrentUserService.instance.getProfileId();

      final posts = result
          .map((data) => PostModel.fromJson(data, currentProfileId))
          .toList();

      photoPosts.assignAll(posts);

      for (final post in posts) {
        debugPrint(
          '[PROFILE POSTS DEBUG] '
          'post=${post.id} '
          'media=${post.mediaUrls.length} '
          'urls=${post.mediaUrls}',
        );
      }

      debugPrint('[PROFILE POSTS] Loaded ${posts.length} posts for $userId');
    } catch (e, stackTrace) {
      debugPrint('[PROFILE POSTS] Error loading user posts: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isPostsLoading(false);
    }
  }

  // ============================================================
  // SAVED POSTS
  // ONLY MY PROFILE
  // ============================================================

  Future<void> loadSavedPosts() async {
    if (!isMyProfile) return;

    if (isSavedPostsLoading.value) return;

    // ----------------------------------------------------------
    // CACHE FIRST
    // ----------------------------------------------------------

    final cachedPosts = CacheManager.getCachedSavedPosts();

    if (cachedPosts.isNotEmpty) {
      savedPosts.assignAll(cachedPosts);

      debugPrint(
        '[PROFILE SAVED] Loaded '
        '${savedPosts.length} posts from cache',
      );
    }

    // ----------------------------------------------------------
    // SERVER
    // ----------------------------------------------------------

    isSavedPostsLoading.value = true;

    try {
      final result = await _postRepo.getSavedPosts();

      savedPosts.assignAll(result);

      await CacheManager.cacheSavedPosts(result);

      debugPrint(
        '[PROFILE SAVED] Server loaded '
        '${savedPosts.length} saved posts',
      );
    } catch (e, stackTrace) {
      debugPrint('[PROFILE SAVED] Error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isSavedPostsLoading.value = false;
    }
  }

  // ============================================================
  // SAVE / UNSAVE
  // ============================================================

  Future<void> onPostSaveChanged(PostModel post, {required bool saved}) async {
    if (!isMyProfile) return;

    if (saved) {
      final alreadyExists = savedPosts.any((item) => item.id == post.id);

      if (!alreadyExists) {
        savedPosts.insert(0, post);
      }

      debugPrint('[PROFILE SAVED] Added ${post.id}');
    } else {
      savedPosts.removeWhere((item) => item.id == post.id);

      debugPrint('[PROFILE SAVED] Removed ${post.id}');
    }

    savedPosts.refresh();

    await CacheManager.cacheSavedPosts(savedPosts.toList());
  }

  // ============================================================
  // IMAGE URLS
  // ============================================================

  String? get avatarUrl {
    final path = profile.value?.avatarPath;

    if (path == null || path.isEmpty) {
      return null;
    }

    return _repo.resolveUrl(path, bucket: 'avatars');
  }

  String? get coverUrl {
    final path = profile.value?.coverPath;

    if (path == null || path.isEmpty) {
      return null;
    }

    return _repo.resolveUrl(path, bucket: 'covers');
  }

  // ============================================================
  // APPLY EDITED OWN PROFILE
  // ============================================================

  Future<void> applyUpdatedProfile(ProfileModel updated) async {
    final old = profile.value;

    if (old?.avatarPath != null && old!.avatarPath != updated.avatarPath) {
      _repo.invalidateUrl(old.avatarPath!, bucket: 'avatars');
    }

    if (old?.coverPath != null && old!.coverPath != updated.coverPath) {
      _repo.invalidateUrl(old.coverPath!, bucket: 'covers');
    }

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
      accountStatus: updated.accountStatus,
      referCode: updated.referCode,
    );

    _applyProfileToState(updatedWithCounts);

    if (isMyProfile) {
      await CacheManager.cacheUserProfile(updatedWithCounts);
    } else {
      await CacheManager.cacheProfileByUserId(updatedWithCounts);
    }

    debugPrint('[PROFILE CACHE] Updated after profile edit');
  }

  // ============================================================
  // FOLLOWERS / FOLLOWING
  // ============================================================

  void openFollowersFollowing(int initialTab) {
    final currentProfile = profile.value;

    if (currentProfile == null) return;

    final uid = currentProfile.id;
    final tag = 'ff_$uid';

    debugPrint(
      '[PROFILE] Opening Followers/Following '
      'uid=$uid tab=$initialTab',
    );

    Get.to(
      () => FollowersFollowingPage(initialTab: initialTab, controllerTag: tag),
      binding: BindingsBuilder(() {
        Get.put(
          FollowersFollowingController(userId: uid, initialTab: initialTab),
          tag: tag,
        );
      }),
    );
  }

  // ============================================================
  // INVALIDATE FOLLOWERS/FOLLOWING
  // ============================================================

  void invalidateFollowersFollowing() {
    final currentProfile = profile.value;

    if (currentProfile == null) return;

    final tag = 'ff_${currentProfile.id}';

    if (Get.isRegistered<FollowersFollowingController>(tag: tag)) {
      Get.find<FollowersFollowingController>(tag: tag).invalidateCache();
    }

    _reloadCounts();
  }

  // ============================================================
  // RELOAD COUNTS
  // ============================================================

  Future<void> _reloadCounts() async {
    final uid = profile.value?.id;

    if (uid == null) return;

    try {
      final counts = await _repo.getFollowCounts(uid);

      followerCount.value = counts.followers;
      followingCount.value = counts.following;

      // Also update the profile object in memory.
      final current = profile.value;

      if (current != null) {
        final updated = ProfileModel(
          id: current.id,
          username: current.username,
          displayName: current.displayName,
          bio: current.bio,
          avatarPath: current.avatarPath,
          coverPath: current.coverPath,
          createdAt: current.createdAt,
          updatedAt: current.updatedAt,
          followerCount: counts.followers,
          followingCount: counts.following,
          postCount: current.postCount,
          accountStatus: current.accountStatus,
          referCode: current.referCode,
        );

        profile.value = updated;

        if (isMyProfile) {
          await CacheManager.cacheUserProfile(updated);
        } else {
          await CacheManager.cacheProfileByUserId(updated);
        }
      }
    } catch (e) {
      debugPrint('[PROFILE] Failed to reload follow counts: $e');
    }
  }
}
