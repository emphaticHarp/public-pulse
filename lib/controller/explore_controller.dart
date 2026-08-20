import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/cache/recent_search_cache.dart';
import 'package:public_pulse/core/repository/profile_repository.dart';
import 'package:public_pulse/model/profile_model.dart';
import 'package:public_pulse/model/recent_search_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/view/profile/profile_page.dart';
import 'package:public_pulse/view/profile/user_profile_page.dart';

class ExploreController extends GetxController {
  final RxList<RecentSearchModel> recentSearches = <RecentSearchModel>[].obs;

  final TextEditingController searchController = TextEditingController();

  final RxString searchText = ''.obs;

  final ProfileRepository _repository = ProfileRepository.instance;

  final RxList<ProfileModel> searchResults = <ProfileModel>[].obs;

  int _searchRequestId = 0;

  String avatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return '';

    return _repository.resolveUrl(avatarPath);
  }

  Future<void> onSearchChanged(String value) async {
    final query = value.trim();

    searchText.value = query;

    final requestId = ++_searchRequestId;

    // Do not search before 3 characters
    if (query.length < 3) {
      searchResults.clear();
      return;
    }

    final results = await _repository.searchUsers(query);

    // Ignore old search results if user typed something newer
    if (requestId != _searchRequestId) {
      return;
    }

    searchResults.assignAll(results);
  }

  Future<bool> _isCurrentUserProfile(String selectedId) async {
    try {
      final currentAuthUserId = Supabase.instance.client.auth.currentUser?.id;

      if (currentAuthUserId == null) {
        return false;
      }

      // ============================================================
      // CASE 1:
      // selectedId itself is profiles.user_id
      // ============================================================

      if (selectedId == currentAuthUserId) {
        return true;
      }

      // ============================================================
      // GET CURRENT USER'S profiles.id
      // ============================================================

      final currentProfile = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('user_id', currentAuthUserId)
          .maybeSingle();

      if (currentProfile == null) {
        return false;
      }

      final currentProfileId = currentProfile['id']?.toString();

      // ============================================================
      // CASE 2:
      // selectedId is profiles.id
      // ============================================================

      final isMine = currentProfileId != null && selectedId == currentProfileId;

      return isMine;
    } catch (e) {
      return false;
    }
  }

  Future<void> openProfile(ProfileModel user) async {
    await addRecentSearch(
      RecentSearchModel(
        userId: user.id,
        username: user.username,
        displayName: user.displayName,
        avatarPath: user.avatarPath,
      ),
    );

    final isMine = await _isCurrentUserProfile(user.id);

    // ============================================================
    // MY PROFILE
    // ============================================================

    if (isMine) {
      if (isMine) {
        Get.to(() => const ProfilePage(openedFromExplore: true));

        return;
      }

      return;
    }

    // ============================================================
    // OTHER USER
    // ============================================================

    Get.to(() => UserProfilePage(userId: user.id));
  }

  // ============================================================
  // OPEN PROFILE FROM RECENT SEARCH
  // ============================================================

  Future<void> openRecentProfile(RecentSearchModel profile) async {
    final isMine = await _isCurrentUserProfile(profile.userId);

    // ============================================================
    // MY PROFILE
    // ============================================================

    if (isMine) {
      if (isMine) {
        Get.to(() => const ProfilePage(openedFromExplore: true));

        return;
      }

      return;
    }

    // ============================================================
    // OTHER USER
    // ============================================================

    Get.to(() => UserProfilePage(userId: profile.userId));
  }

  @override
  void onInit() {
    super.onInit();
    loadRecentSearches();
  }

  void loadRecentSearches() {
    recentSearches.assignAll(RecentSearchCache.getSearches());
  }

  Future<void> addRecentSearch(RecentSearchModel profile) async {
    await RecentSearchCache.addSearch(profile);
    loadRecentSearches();
  }

  Future<void> removeRecentSearch(RecentSearchModel profile) async {
    await RecentSearchCache.removeSearch(profile);
    loadRecentSearches();
  }

  Future<void> clearRecentSearches() async {
    await RecentSearchCache.clearAll();
    loadRecentSearches();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
