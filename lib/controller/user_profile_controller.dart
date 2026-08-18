import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/profile_model.dart';
import '../model/post_model.dart';
import '../core/repository/user_profile_repository.dart';
import '../core/repository/profile_repository.dart';
import '../core/services/current_user_service.dart';
import 'package:public_pulse/controller/home_controller.dart';
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
  // POSTS — full PostModel list for tap-to-detail
  // ─────────────────────────────────────────────

  final photoPosts = <PostModel>[].obs;

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
      // Fetch profile and follow state concurrently.
      final results = await Future.wait([
        _repo.getUserProfile(userId),
        _repo.isFollowing(userId),
        _repo.isFollowedBy(userId),
        _repo.getProfileIdFromUserId(userId),
      ]);
      final loadedProfile = results[0] as ProfileModel;

      avatarUrl = loadedProfile.avatarPath != null
          ? _repo.resolveUrl(loadedProfile.avatarPath!, bucket: 'avatars')
          : null;

      coverUrl = loadedProfile.coverPath != null
          ? _repo.resolveUrl(loadedProfile.coverPath!, bucket: 'covers')
          : null;

      profile.value = loadedProfile;
      followerCount.value = loadedProfile.followerCount ?? 0;
      followingCount.value = loadedProfile.followingCount ?? 0;
      isFollowing.value = results[1] as bool;
      followsMe.value = results[2] as bool;

      final targetProfileId = results[3] as String;

      // Keep HomeController follow state synchronized.
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();

        if (isFollowing.value) {
          homeController.followingIds.add(targetProfileId);
        } else {
          homeController.followingIds.remove(targetProfileId);
        }

        homeController.followingIds.refresh();
      }

      // Fetch full PostModel list for the grid (enables tap-to-detail).
      await _loadUserPosts();
    } catch (e) {
      debugPrint('[USER_PROFILE] ERROR: $e');
    } finally {
      isLoading(false);
    }
  }

  // Resolves auth userId → internal profiles.id, then fetches PostModels.
  Future<void> _loadUserPosts() async {
    try {
      // Look up internal profile UUID from auth user_id.
      final row = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final internalProfileId = row['id'] as String;

      final currentProfileId = await CurrentUserService.instance.getProfileId();

      final rawPosts = await ProfileRepository.instance.getUserPostsByProfileId(
        internalProfileId,
      );

      photoPosts.assignAll(
        rawPosts
            .map((data) => PostModel.fromJson(data, currentProfileId))
            .toList(),
      );
    } catch (e) {
      debugPrint('[USER_PROFILE] Post load error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // FOLLOW BUTTON LABEL
  // ─────────────────────────────────────────────

  String get followButtonLabel {
    if (isFollowing.value) return 'Following';
    if (followsMe.value) return 'Follow Back';
    return 'Follow';
  }

  // ─────────────────────────────────────────────
  // TOGGLE FOLLOW
  // ─────────────────────────────────────────────
  Future<void> toggleFollow() async {
    if (isFollowLoading.value) return;

    isFollowLoading.value = true;

    final wasFollowing = isFollowing.value;
    final oldFollowerCount = followerCount.value;

    try {
      final targetProfileId = await _repo.getProfileIdFromUserId(userId);

      // ─────────────────────────────────────────
      // OPTIMISTIC PROFILE UI
      // ─────────────────────────────────────────

      isFollowing.value = !wasFollowing;

      followerCount.value = wasFollowing
          ? (followerCount.value - 1).clamp(0, 999999999)
          : followerCount.value + 1;

      // ─────────────────────────────────────────
      // SYNC HOME FOLLOW STATE
      // ─────────────────────────────────────────

      HomeController? homeController;

      if (Get.isRegistered<HomeController>()) {
        homeController = Get.find<HomeController>();

        if (wasFollowing) {
          homeController.followingIds.remove(targetProfileId);
        } else {
          homeController.followingIds.add(targetProfileId);
        }

        homeController.followingIds.refresh();
      }

      // ─────────────────────────────────────────
      // SERVER
      // ─────────────────────────────────────────

      if (wasFollowing) {
        await _repo.unfollowUser(userId);
      } else {
        await _repo.followUser(userId);
      }
    } catch (e) {
      debugPrint('[USER_PROFILE] FOLLOW ERROR: $e');

      // Rollback profile UI
      isFollowing.value = wasFollowing;
      followerCount.value = oldFollowerCount;

      // Rollback Home state too
      try {
        if (Get.isRegistered<HomeController>()) {
          final homeController = Get.find<HomeController>();

          final targetProfileId = await _repo.getProfileIdFromUserId(userId);

          if (wasFollowing) {
            homeController.followingIds.add(targetProfileId);
          } else {
            homeController.followingIds.remove(targetProfileId);
          }

          homeController.followingIds.refresh();
        }
      } catch (_) {}
    } finally {
      isFollowLoading.value = false;
    }
  }
  // ─────────────────────────────────────────────
  // TAB
  // ─────────────────────────────────────────────

  void changeTab(ProfileTab tab) => selectedTab.value = tab;

  // ─────────────────────────────────────────────
  // FOLLOWERS / FOLLOWING PAGE
  // ─────────────────────────────────────────────

  void openFollowersFollowing(int initialTab) {
    if (!Get.isRegistered<FollowersFollowingController>(tag: ffTag)) {
      Get.put(
        FollowersFollowingController(userId: userId, initialTab: initialTab),
        tag: ffTag,
      );
    }

    final controller = Get.find<FollowersFollowingController>(tag: ffTag);

    controller.switchTab(initialTab);

    // Always refresh from Supabase when opening the list.
    // Existing cached data stays visible while refreshing.
    if (initialTab == 0) {
      controller.loadFollowers(forceRefresh: true);
    } else {
      controller.loadFollowing(forceRefresh: true);
    }

    Get.to(
      () =>
          FollowersFollowingPage(initialTab: initialTab, controllerTag: ffTag),
    );
  }
}
