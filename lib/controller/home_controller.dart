import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/model/post_model.dart';
import 'package:public_pulse/core/repository/post_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:public_pulse/core/cache/cache_manager.dart';

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

  /// Cursor Pagination
  String? nextCursor;

  final hasMore = true.obs;

  final isLoadingMore = false.obs;

  @override
  void onInit() {
    super.onInit();

    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      debugPrint('[DEBUG-CONTROLLER] User logged in');

      loadCachedPosts();
      loadPosts();
      loadMyPosts();

      scrollController.addListener(_onScroll);
    } else {
      debugPrint('[DEBUG-CONTROLLER] User not logged in');
    }
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;

    // Start loading more when 300px from the bottom
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      loadMorePosts();
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

  final ScrollController scrollController = ScrollController();

  @override
  void onClose() {
    scrollController.dispose();

    for (final pc in _carouselPageControllers.values) {
      pc.dispose();
    }
    _carouselPageControllers.clear();
    super.onClose();
  }

  void loadCachedPosts() {
    debugPrint('[DEBUG-CONTROLLER] Loading cached posts...');

    final cachedPosts = CacheManager.getCachedPosts();

    if (cachedPosts.isEmpty) {
      debugPrint('[DEBUG-CONTROLLER] No cached posts found');
      return;
    }

    posts.assignAll(cachedPosts);

    nextCursor = CacheManager.getNextCursor();
    hasMore.value = CacheManager.getHasMore();

    debugPrint('[DEBUG-CONTROLLER] Loaded ${cachedPosts.length} cached posts');
  }

  Future<void> loadPosts() async {
    try {
      if (posts.isEmpty) {
        isLoading.value = true;
      }

      final page = await _repository.getPosts(cursor: null, limit: 10);

      nextCursor = page.nextCursor;
      hasMore.value = page.hasMore;

      // Repository already returns merged + sorted posts.
      posts.assignAll(page.posts);

      await CacheManager.cachePosts(
        posts,
        nextCursor: nextCursor,
        hasMore: hasMore.value,
      );

      debugPrint('[DEBUG-CONTROLLER] Feed refreshed: ${posts.length} posts');
    } catch (e, stackTrace) {
      debugPrint('[DEBUG-CONTROLLER] loadPosts ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMorePosts() async {
    if (isLoadingMore.value) return;

    if (!hasMore.value) return;

    isLoadingMore.value = true;

    try {
      final page = await _repository.getPosts(cursor: nextCursor, limit: 10);

      nextCursor = page.nextCursor;
      hasMore.value = page.hasMore;

      posts.assignAll(page.posts);

      await CacheManager.cachePosts(
        posts,
        nextCursor: nextCursor,
        hasMore: hasMore.value,
      );

      debugPrint('[DEBUG-CONTROLLER] Loaded ${page.posts.length} more posts');
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      isLoadingMore.value = false;
    }
  }
}
