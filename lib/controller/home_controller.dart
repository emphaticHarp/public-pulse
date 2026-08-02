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

  /// Track previously loaded post IDs to detect duplicates
  final Set<String> _previouslyLoadedPostIds = {};

  @override
  void onInit() {
    super.onInit();

    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      loadCachedPosts();

      if (posts.isEmpty) {
        loadPosts(); // first install only
      } else {
        _startNewPostChecker(); // cache already exists
      }

      loadMyPosts();

      scrollController.addListener(_onScroll);
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

  /// Helper: Detect and log duplicate post IDs
  void _logDuplicateCheck(String source, List<PostModel> newPosts) {
    final newIds = newPosts.map((p) => p.id).toSet();
    final duplicates = newIds.intersection(_previouslyLoadedPostIds);
    if (duplicates.isNotEmpty) {
      debugPrint(
        '[POST-TRACE] ⚠️ DUPLICATE DETECTED ($source): '
        '${duplicates.length} posts already loaded: $duplicates',
      );
    }
    // Register these IDs as seen
    _previouslyLoadedPostIds.addAll(newIds);
  }

  /// Helper: Log post IDs with their source
  void _logPostSource(String source, List<PostModel> postList) {
    final ids = postList.map((p) => p.id).toList();
    debugPrint(
      '[POST-TRACE] $source → ${postList.length} posts | IDs: $ids',
    );
  }

  Future<void> loadMyPosts() async {
    try {
      // Load posts through the repository.
      // The repository automatically returns Hive cached posts first
      // (if cache is still valid), otherwise it fetches fresh data
      // from Supabase and updates the cache.
      final fetchedPosts = await _repository.getMyPosts();

      myPosts.assignAll(fetchedPosts);
    } catch (e, stackTrace) {
      debugPrint('[ERROR] loadMyPosts: $e');
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
    final cachedPosts = CacheManager.getCachedPosts();

    if (cachedPosts.isEmpty) {
      debugPrint('[CACHE] No cached posts found → will fetch from Supabase');
      return;
    }

    _logPostSource('[CACHE] Loaded from Hive cache', cachedPosts);

    posts.assignAll(cachedPosts);

    nextCursor = CacheManager.getNextCursor();
    hasMore.value = CacheManager.getHasMore();

    // Register cached posts as seen
    for (final p in cachedPosts) {
      _previouslyLoadedPostIds.add(p.id);
    }

    // FIX: Set isLoading to false after loading from cache so the loader
    // disappears immediately. Without this, isLoading stays true forever
    // when cache exists, because loadPosts() is never called.
    isLoading.value = false;
  }

  Future<void> loadPosts() async {
    try {
      if (posts.isEmpty) {
        isLoading.value = true;
      }

      final page = await _repository.getInitialPosts(limit: 10);

      nextCursor = page.nextCursor;
      hasMore.value = page.hasMore;

      _logPostSource('[SUPABASE] Fetched initial posts', page.posts);
      _logDuplicateCheck('loadPosts', page.posts);

      posts.assignAll(page.posts);

      await CacheManager.cachePosts(
        posts,
        nextCursor: nextCursor,
        hasMore: hasMore.value,
      );

      if (_newPostTimer == null) {
        _startNewPostChecker();
      }
    } catch (e, stackTrace) {
      debugPrint('[ERROR] loadPosts: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshFeed() async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      final page = await _repository.getInitialPosts(limit: 10);

      _logPostSource('[SUPABASE] Refreshed feed', page.posts);
      _logDuplicateCheck('refreshFeed', page.posts);

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
    } catch (e) {
      debugPrint('[ERROR] refreshFeed: $e');
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

      _logPostSource('[SUPABASE] Loaded more posts (pagination)', page.posts);
      _logDuplicateCheck('loadMorePosts', page.posts);

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
    } catch (e) {
      debugPrint('[ERROR] loadMorePosts: $e');
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

      if (newPosts.isEmpty) return;

      for (final post in newPosts) {
        if (!pendingPosts.any((e) => e.id == post.id)) {
          pendingPosts.add(post);
        }
      }

      newPostCount.value = pendingPosts.length;

      debugPrint(
        '[POST-TRACE] [SUPABASE] New posts check: '
        '${newPosts.length} new, ${pendingPosts.length} pending',
      );
    } catch (e) {
      debugPrint('[ERROR] _checkForNewPosts: $e');
    }
  }
}
