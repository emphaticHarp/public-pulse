import 'dart:async';
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

  /// Posts waiting for refresh
  final RxList<PostModel> pendingPosts = <PostModel>[].obs;

  /// Number of new posts
  final RxInt newPostCount = 0.obs;

  /// Timer for background checking
  Timer? _newPostTimer;

  

  @override
  void onInit() {
    super.onInit();

    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      debugPrint('[DEBUG-CONTROLLER] User logged in');

      loadCachedPosts();

      if (posts.isEmpty) {
        loadPosts(); // first install only
      } else {
        _startNewPostChecker(); // cache already exists
      }

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
    _newPostTimer?.cancel();
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

      final page = await _repository.getInitialPosts(limit: 10);

      nextCursor = page.nextCursor;
      hasMore.value = page.hasMore;

    posts.assignAll(page.posts);//--------changed------



      await CacheManager.cachePosts(
        posts,
        nextCursor: nextCursor,
        hasMore: hasMore.value,
      );

      if (_newPostTimer == null) {
        _startNewPostChecker();
      }

      debugPrint('[DEBUG-CONTROLLER] Feed refreshed: ${posts.length} posts');
    } catch (e, stackTrace) {
      debugPrint('[DEBUG-CONTROLLER] loadPosts ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshFeed() async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      debugPrint('[DEBUG] Refresh Feed');

      final page = await _repository.getInitialPosts(limit: 10);

      nextCursor = page.nextCursor;
      hasMore.value = page.hasMore;

      // IDs of currently loaded posts
      final Map<String, PostModel> mergedMap = {};

      for (final post in page.posts) {
        mergedMap[post.id] = post;
      }

      for (final post in posts) {
        mergedMap.putIfAbsent(post.id, () => post);
      }

      posts.assignAll(mergedMap.values.toList());

      pendingPosts.clear();
      newPostCount.value = 0;

      await CacheManager.cachePosts(
        posts,
        nextCursor: nextCursor,
        hasMore: hasMore.value,
      );

      debugPrint('[DEBUG] Feed refreshed');
    } catch (e) {
      debugPrint('[DEBUG] refreshFeed ERROR: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMorePosts() async {
    if (isLoadingMore.value) return;

    if (!hasMore.value) return;

    isLoadingMore.value = true;

    try {
      final page = await _repository.getMorePosts(
        cursor: nextCursor!,
        limit: 10,
      );

      nextCursor = page.nextCursor;
      hasMore.value = page.hasMore;

      final existingIds = posts.map((e) => e.id).toSet();

      for (final post in page.posts) {
        if (!existingIds.contains(post.id)) {
          posts.add(post);
        }
      }

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

  void _startNewPostChecker() {
    _newPostTimer?.cancel();

    _newPostTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      if (Get.currentRoute != '/home') return;

      await _checkForNewPosts();
    });

    debugPrint('[DEBUG] New post checker started');
  }

  Future<void> _checkForNewPosts() async {
    try {
      // Don't check while the feed is loading or paginating
      if (isLoading.value || isLoadingMore.value) return;

      if (posts.isEmpty) return;

      final latestCreatedAt = posts.first.createdAt.toIso8601String();

      final newPosts = await _repository.getNewPosts(
        latestCreatedAt: latestCreatedAt,
      );

      if (newPosts.isEmpty) {
        debugPrint('[DEBUG] No new posts');
        return;
      }

      for (final post in newPosts) {
        if (!pendingPosts.any((e) => e.id == post.id)) {
          pendingPosts.add(post);
        }
      }

      newPostCount.value = pendingPosts.length;

      debugPrint('[DEBUG] Pending Posts = ${pendingPosts.length}');
    } catch (e) {
      debugPrint('[DEBUG] _checkForNewPosts ERROR: $e');
    }
  }
}
