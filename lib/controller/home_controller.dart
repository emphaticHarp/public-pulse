import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/model/post_model.dart';
import 'package:public_pulse/core/repository/post_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeController extends GetxController {
  final RxInt currentIndex = 0.obs;

  /// Per-post carousel index: postId -> current page index
  final RxMap<String, int> carouselIndexes = <String, int>{}.obs;

  /// Per-post fractional scroll position for smooth dot animations
  final RxMap<String, double> carouselScrollFractions = <String, double>{}.obs;

  /// Per-post PageControllers for carousel posts
  final Map<String, PageController> _carouselPageControllers = {};

  final PostRepository _repository = PostRepository();

  /// Home feed (everyone's posts)
  final RxList<PostModel> posts = <PostModel>[].obs;

  /// Logged in user's posts
  final RxList<PostModel> myPosts = <PostModel>[].obs;

  /// Loading state for home feed
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();

    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      debugPrint('[DEBUG-CONTROLLER] User logged in');

      loadPosts();
      loadMyPosts();
    } else {
      debugPrint('[DEBUG-CONTROLLER] User not logged in');
    }
  }

  Future<void> loadMyPosts() async {
    try {
      // Load posts through the repository.
      // The repository automatically returns Hive cached posts first
      // (if cache is still valid), otherwise it fetches fresh data
      // from Supabase and updates the cache.
      final fetchedPosts = await _repository.getMyPosts();

      myPosts.assignAll(fetchedPosts);

      debugPrint('[DEBUG-CONTROLLER] My Posts loaded: ${myPosts.length}');
    } catch (e, stackTrace) {
      debugPrint('[DEBUG-CONTROLLER] loadMyPosts ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Get or create a PageController for a carousel post
  PageController getCarouselPageController(String postId, int initialPage) {
    if (!_carouselPageControllers.containsKey(postId)) {
      final pc = PageController(initialPage: initialPage);
      _carouselPageControllers[postId] = pc;
      pc.addListener(() {
        if (pc.hasClients && pc.page != null) {
          final currentPage = pc.page!;
          final intPage = currentPage.round();
          final fraction = currentPage - intPage;
          if (carouselIndexes[postId] != intPage) {
            carouselIndexes[postId] = intPage;
          }
          carouselScrollFractions[postId] = fraction;
        }
      });
    }
    return _carouselPageControllers[postId]!;
  }

  @override
  void onClose() {
    for (final pc in _carouselPageControllers.values) {
      pc.dispose();
    }
    _carouselPageControllers.clear();
    super.onClose();
  }

  Future<void> loadPosts() async {
    debugPrint('[DEBUG-CONTROLLER] loadPosts: Starting...');
    try {
      isLoading.value = true;
      debugPrint('[DEBUG-CONTROLLER] loadPosts: isLoading set to true');

      final fetchedPosts = await _repository.getPosts();
      debugPrint('[DEBUG-CONTROLLER] loadPosts: Fetched ${fetchedPosts.length} posts from repository');
      debugPrint('[DEBUG-CONTROLLER] loadPosts: Fetched post IDs: ${fetchedPosts.map((e) => e.id).toList()}');

      debugPrint('[DEBUG-CONTROLLER] loadPosts: Before assignAll, posts.length = ${posts.length}');
      posts.assignAll(fetchedPosts);
      debugPrint('[DEBUG-CONTROLLER] loadPosts: After assignAll, posts.length = ${posts.length}');
      debugPrint('[DEBUG-CONTROLLER] loadPosts: Current posts list IDs: ${posts.map((e) => e.id).toList()}');

    } catch (e, stackTrace) {
      debugPrint('[DEBUG-CONTROLLER] loadPosts ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
      debugPrint('[DEBUG-CONTROLLER] loadPosts: isLoading set to false');
    }
  }
}
