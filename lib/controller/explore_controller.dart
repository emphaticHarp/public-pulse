import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/cache/recent_search_cache.dart';
import 'package:public_pulse/core/repository/profile_repository.dart';
import 'package:public_pulse/model/profile_model.dart';
import 'package:public_pulse/model/recent_search_model.dart';

import 'package:public_pulse/view/profile/user_profile_page.dart';

class ExploreController extends GetxController {
  final RxList<RecentSearchModel> recentSearches = <RecentSearchModel>[].obs;

  final TextEditingController searchController = TextEditingController();

  final RxString searchText = ''.obs;

  final ProfileRepository _repository = ProfileRepository.instance;

  final RxList<ProfileModel> searchResults = <ProfileModel>[].obs;

  String avatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return '';

    return _repository.resolveUrl(avatarPath);
  }

  Future<void> onSearchChanged(String value) async {
    searchText.value = value;

    if (value.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    searchResults.assignAll(await _repository.searchUsers(value));
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

    //redirection to user profile page with the user id and binding the controller to the user id

    Get.to(() => UserProfilePage(userId: user.id));
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
