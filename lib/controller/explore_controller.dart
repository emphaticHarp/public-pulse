import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/cache/recent_search_cache.dart';
import 'package:public_pulse/core/repository/profile_repository.dart';
import 'package:public_pulse/model/profile_model.dart';

class ExploreController extends GetxController {
 final RxList<ProfileModel> recentSearches = <ProfileModel>[].obs;

  final TextEditingController searchController = TextEditingController();

  final RxString searchText = ''.obs;

  final ProfileRepository _repository = ProfileRepository.instance;

  final RxList<ProfileModel> searchResults = <ProfileModel>[].obs;

  String avatarUrl(ProfileModel profile) {
  if (profile.avatarPath == null) return '';

  return _repository.resolveUrl(profile.avatarPath!);
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
  await addRecentSearch(user);

  // TODO:
  // Get.to(() => ProfilePage(userId: user.id));
}

  @override
  void onInit() {
    super.onInit();
    loadRecentSearches();
  }

  void loadRecentSearches() {
    recentSearches.assignAll(RecentSearchCache.getSearches());
  }

  Future<void> addRecentSearch(ProfileModel profile) async {
    await RecentSearchCache.addSearch(profile);
    loadRecentSearches();
  }

  Future<void> removeRecentSearch(ProfileModel profile) async {
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
