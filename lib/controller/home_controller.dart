import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:public_pulse/model/post_model.dart';
import 'package:public_pulse/core/repository/post_repository.dart';
import 'package:public_pulse/core/cache/cache_manager.dart';
import 'package:public_pulse/core/repository/follow_repository.dart';
import 'package:public_pulse/widget/local/app_alert.dart';
import 'package:public_pulse/controller/profile_controller.dart';

class HomeController extends GetxController {
  // ============================================================
  // TAB
  // ============================================================

  final RxInt currentIndex = 0.obs;

  // ============================================================
  // POSTS
  // ============================================================

  /// Home feed.
  final RxList<PostModel> posts = <PostModel>[].obs;

  /// Logged-in user's posts.
  final RxList<PostModel> myPosts = <PostModel>[].obs;

  /// Users currently followed by the logged-in user.
  final RxSet<String> followingIds = <String>{}.obs;

  // ============================================================
  // LOADING
  // ============================================================

  final RxBool isLoading = true.obs;

  final RxBool isLoadingMore = false.obs;

  // ============================================================
  // PAGINATION
  // ============================================================

  String? nextCursor;

  final RxBool hasMore = true.obs;

  // ============================================================
  // NEW POSTS
  // ============================================================

  /// Posts found by the background checker but not yet inserted.
  final RxList<PostModel> pendingPosts = <PostModel>[].obs;

  final RxInt newPostCount = 0.obs;

  Timer? _newPostTimer;

  // ============================================================
  // CAROUSEL
  // ============================================================

  /// postId -> current carousel page.
  final RxMap<String, int> carouselIndexes = <String, int>{}.obs;

  /// postId -> fractional carousel position.
  final RxMap<String, double> carouselScrollFractions = <String, double>{}.obs;

  /// PageController for each carousel post.
  final Map<String, PageController> _carouselPageControllers = {};

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final ScrollController scrollController = ScrollController();

  // ============================================================
  // REPOSITORY
  // ============================================================

  final PostRepository _repository = PostRepository();

  // ============================================================
  // DEBUG
  // ============================================================

  final Set<String> _previouslyLoadedPostIds = {};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void onInit() {
    super.onInit();

    debugPrint('[HOME] HomeController created');

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      debugPrint('[HOME] No authenticated user');
      isLoading.value = false;
      return;
    }

    scrollController.addListener(_onScroll);

    _initializeHome();
  }

  // ============================================================
  // HOME INITIALIZATION
  // ============================================================

  Future<void> _initializeHome() async {
    debugPrint('[HOME] ===== INITIALIZATION START =====');

    loadCachedPosts();

    await loadPosts();

    loadMyPosts();
    loadFollowingIds();

    _startNewPostChecker();

    debugPrint('[HOME] ===== INITIALIZATION COMPLETE =====');
  }
  // ============================================================
  // SCROLL / PAGINATION
  // ============================================================

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final position = scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 300) {
      loadMorePosts();
    }
  }

  // ============================================================
  // DEBUG HELPERS
  // ============================================================

  void _logPostSource(String source, List<PostModel> postList) {
    final ids = postList.map((post) => post.id).toList();

    debugPrint(
      '[POST-TRACE] $source → '
      '${postList.length} posts | IDs: $ids',
    );
  }

  void _logDuplicateCheck(String source, List<PostModel> newPosts) {
    final newIds = newPosts.map((post) => post.id).toSet();

    final duplicates = newIds.intersection(_previouslyLoadedPostIds);

    if (duplicates.isNotEmpty) {
      debugPrint(
        '[POST-TRACE] DUPLICATE ($source): '
        '${duplicates.length} → $duplicates',
      );
    }

    _previouslyLoadedPostIds.addAll(newIds);
  }

  // ============================================================
  // CACHE
  // ============================================================

  void loadCachedPosts() {
    final cachedPosts = CacheManager.getCachedPosts();

    if (cachedPosts.isEmpty) {
      debugPrint('[CACHE] No cached posts found');
      return;
    }

    debugPrint('[CACHE] Loading ${cachedPosts.length} posts from Hive');

    _logPostSource('[CACHE] Hive', cachedPosts);

    posts.assignAll(cachedPosts);

    nextCursor = CacheManager.getNextCursor();

    hasMore.value = CacheManager.getHasMore();

    _previouslyLoadedPostIds
      ..clear()
      ..addAll(cachedPosts.map((post) => post.id));

    // Cached feed is immediately available.
    isLoading.value = false;

    debugPrint(
      '[CACHE] Feed loaded from Hive '
      '→ ${posts.length} posts',
    );
  }

  // ============================================================
  // INITIAL POSTS
  // ============================================================

  Future<void> loadPosts() async {
    try {
      debugPrint('[HOME] Fetching initial posts');

      final page = await _repository.getInitialPosts(limit: 10);

      nextCursor = page.nextCursor;

      hasMore.value = page.hasMore;

      _logPostSource('[SUPABASE] Initial posts', page.posts);

      // ----------------------------------------------------------
      // Server is authoritative for the first page.
      // ----------------------------------------------------------

      final cacheIds = posts.map((post) => post.id).toList();

      final serverIds = page.posts.map((post) => post.id).toList();

      if (cacheIds.toString() != serverIds.toString()) {
        posts.assignAll(page.posts);

        _previouslyLoadedPostIds
          ..clear()
          ..addAll(page.posts.map((post) => post.id));

        debugPrint('[HOME] Feed changed → UI updated');
      } else {
        debugPrint('[HOME] Server feed same as cache');
      }

      await CacheManager.cachePosts(
        posts,
        nextCursor: nextCursor,
        hasMore: hasMore.value,
      );
    } catch (e, stackTrace) {
      debugPrint('[HOME] loadPosts error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // MANUAL REFRESH
  // ============================================================

  Future<void> refreshFeed() async {
    if (isLoading.value) return;

    debugPrint('[HOME] ===============================');
    debugPrint('[HOME] MANUAL REFRESH');
    debugPrint('[HOME] ===============================');

    isLoading.value = true;

    try {
      final page = await _repository.getInitialPosts(limit: 10);

      nextCursor = page.nextCursor;

      hasMore.value = page.hasMore;

      _logPostSource('[SUPABASE] Manual refresh', page.posts);

      // Server is the source of truth.
      posts.assignAll(page.posts);

      _previouslyLoadedPostIds
        ..clear()
        ..addAll(page.posts.map((post) => post.id));

      pendingPosts.clear();

      newPostCount.value = 0;

      await CacheManager.cachePosts(
        posts,
        nextCursor: nextCursor,
        hasMore: hasMore.value,
      );

      debugPrint(
        '[HOME] Refresh complete '
        '→ ${posts.length} posts',
      );
    } catch (e, stackTrace) {
      debugPrint('[HOME] refreshFeed error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // MY POSTS
  // ============================================================

  Future<void> loadMyPosts() async {
    try {
      final fetchedPosts = await _repository.getMyPosts();

      myPosts.assignAll(fetchedPosts);

      debugPrint(
        '[HOME] My posts loaded '
        '→ ${myPosts.length}',
      );
    } catch (e, stackTrace) {
      debugPrint('[HOME] loadMyPosts error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // FOLLOWING IDS
  // ============================================================

  Future<void> loadFollowingIds() async {
    try {
      // ----------------------------------------------------------
      // Hive first.
      // ----------------------------------------------------------

      final cached = CacheManager.getCachedFollowingIds();

      if (cached.isNotEmpty) {
        followingIds.value = cached;

        debugPrint('[FOLLOW] Loaded ${cached.length} IDs from cache');
      }

      // ----------------------------------------------------------
      // Server refresh.
      // ----------------------------------------------------------

      final server = await FollowRepository.instance.getFollowingIds();

      followingIds.value = server;

      await CacheManager.cacheFollowingIds(server);

      debugPrint(
        '[FOLLOW] Server following IDs '
        '→ ${server.length}',
      );
    } catch (e, stackTrace) {
      debugPrint('[FOLLOW] loadFollowingIds error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // FOLLOW
  // ============================================================

  Future<void> followUser(String profileId) async {
    // Optimistic UI.
    followingIds.add(profileId);

    followingIds.refresh();

    await CacheManager.cacheFollowingIds(followingIds.toSet());

    final success = await FollowRepository.instance.followUser(profileId);

    if (!success) {
      followingIds.remove(profileId);

      followingIds.refresh();

      await CacheManager.cacheFollowingIds(followingIds.toSet());
    }
  }

  // ============================================================
  // UNFOLLOW
  // ============================================================

  Future<void> unfollowUser(String profileId) async {
    // Optimistic UI.
    followingIds.remove(profileId);

    followingIds.refresh();

    await CacheManager.cacheFollowingIds(followingIds.toSet());

    final success = await FollowRepository.instance.unfollowUser(profileId);

    if (!success) {
      followingIds.add(profileId);

      followingIds.refresh();

      await CacheManager.cacheFollowingIds(followingIds.toSet());
    }
  }

  // ============================================================
  // LIKE
  // ============================================================

  Future<void> toggleLike(PostModel post) async {
    final oldLiked = post.isLiked;
    final oldCount = post.likeCount;

    // Optimistic UI.
    post.isLiked = !oldLiked;

    if (post.isLiked) {
      post.likeCount++;
    } else {
      post.likeCount--;
    }

    posts.refresh();

    await CacheManager.cachePosts(
      posts,
      nextCursor: nextCursor,
      hasMore: hasMore.value,
    );

    final success = await _repository.toggleLike(
      postId: post.id,
      currentlyLiked: oldLiked,
    );

    if (!success) {
      post.isLiked = oldLiked;
      post.likeCount = oldCount;

      posts.refresh();

      await CacheManager.cachePosts(
        posts,
        nextCursor: nextCursor,
        hasMore: hasMore.value,
      );
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> toggleSave(PostModel post) async {
    final oldSaved = post.isSaved;

    // ============================================================
    // 1. OPTIMISTIC UI
    // ============================================================

    post.isSaved = !oldSaved;

    posts.refresh();

    await CacheManager.cachePosts(
      posts,
      nextCursor: nextCursor,
      hasMore: hasMore.value,
    );

    // ============================================================
    // 2. UPDATE PROFILE SAVED POSTS IMMEDIATELY
    // ============================================================

    if (Get.isRegistered<ProfileController>()) {
      await ProfileController.to.onPostSaveChanged(post, saved: post.isSaved);
    }

    // ============================================================
    // 3. UPDATE SUPABASE
    // ============================================================

    final success = await _repository.toggleSave(
      postId: post.id,
      currentlySaved: oldSaved,
    );

    // ============================================================
    // 4. ROLLBACK IF SERVER FAILED
    // ============================================================

    if (!success) {
      post.isSaved = oldSaved;

      posts.refresh();

      await CacheManager.cachePosts(
        posts,
        nextCursor: nextCursor,
        hasMore: hasMore.value,
      );

      // Roll back Profile page too.
      if (Get.isRegistered<ProfileController>()) {
        await ProfileController.to.onPostSaveChanged(post, saved: oldSaved);
      }
    }
  }
  // ============================================================
  // LOAD MORE
  // ============================================================

  Future<void> loadMorePosts() async {
    if (isLoadingMore.value) return;

    if (!hasMore.value) return;

    if (nextCursor == null) return;

    isLoadingMore.value = true;

    try {
      final page = await _repository.getMorePosts(
        cursor: nextCursor!,
        limit: 10,
      );

      _logPostSource('[SUPABASE] Pagination', page.posts);

      nextCursor = page.nextCursor;

      hasMore.value = page.hasMore;

      final existingIds = posts.map((post) => post.id).toSet();

      for (final post in page.posts) {
        if (!existingIds.contains(post.id)) {
          posts.add(post);
          existingIds.add(post.id);
          _previouslyLoadedPostIds.add(post.id);
        }
      }

      await CacheManager.cachePosts(
        posts,
        nextCursor: nextCursor,
        hasMore: hasMore.value,
      );
    } catch (e, stackTrace) {
      debugPrint('[HOME] loadMorePosts error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ============================================================
  // NEW POST CHECKER
  // ============================================================

  void _startNewPostChecker() {
    if (_newPostTimer != null) {
      return;
    }

    debugPrint('[HOME] Starting new-post checker');

    _newPostTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      // --------------------------------------------------------
      // IMPORTANT:
      // MainPage uses IndexedStack.
      //
      // 0 = Home
      // 1 = Explore
      // 2 = Notification
      // 3 = Profile
      //
      // Therefore Get.currentRoute MUST NOT be used here.
      // --------------------------------------------------------

      if (currentIndex.value != 0) {
        debugPrint(
          '[HOME] New-post check skipped '
          'because Home tab is not active',
        );
        return;
      }

      await _checkForNewPosts();
    });
  }

  Future<void> _checkForNewPosts() async {
    try {
      if (currentIndex.value != 0) return;

      if (isLoading.value) return;

      if (isLoadingMore.value) return;

      if (posts.isEmpty) return;

      final latestCreatedAt = posts.first.createdAt.toIso8601String();

      final newPosts = await _repository.getNewPosts(
        latestCreatedAt: latestCreatedAt,
      );

      if (newPosts.isEmpty) {
        return;
      }

      final existingPendingIds = pendingPosts.map((post) => post.id).toSet();

      for (final post in newPosts) {
        if (!existingPendingIds.contains(post.id) &&
            !posts.any((e) => e.id == post.id)) {
          pendingPosts.add(post);
          existingPendingIds.add(post.id);
        }
      }

      newPostCount.value = pendingPosts.length;

      debugPrint(
        '[HOME] New posts found '
        '→ ${pendingPosts.length} pending',
      );
    } catch (e, stackTrace) {
      debugPrint('[HOME] New post checker error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // SINGLE POST COMMENT COUNT
  // ============================================================

  Future<void> refreshSinglePost(String postId) async {
    try {
      final response = await Supabase.instance.client
          .from('posts')
          .select('comment_count')
          .eq('id', postId)
          .single();

      final index = posts.indexWhere((post) => post.id == postId);

      if (index == -1) return;

      posts[index].commentCount = response['comment_count'] ?? 0;

      posts.refresh();

      await CacheManager.cachePosts(
        posts,
        nextCursor: nextCursor,
        hasMore: hasMore.value,
      );
    } catch (e) {
      debugPrint('[HOME] refreshSinglePost error: $e');
    }
  }

  // ============================================================
  // DELETE POST
  // ============================================================

  Future<void> deletePost(String postId) async {
    final index = posts.indexWhere((post) => post.id == postId);

    if (index == -1) return;

    final removedPost = posts[index];

    // Optimistic delete.
    posts.removeAt(index);

    _previouslyLoadedPostIds.remove(postId);

    await CacheManager.cachePosts(
      posts,
      nextCursor: nextCursor,
      hasMore: hasMore.value,
    );

    final success = await _repository.deletePost(postId);

    if (!success) {
      // Rollback.
      posts.insert(index, removedPost);

      _previouslyLoadedPostIds.add(postId);

      await CacheManager.cachePosts(
        posts,
        nextCursor: nextCursor,
        hasMore: hasMore.value,
      );

      CustomAlert.show(
        title: 'Error',
        message: 'Failed to delete post',
        icon: Icons.error_outline,
        color: Colors.red,
      );

      return;
    }

    CustomAlert.show(
      title: 'Deleted',
      message: 'Post deleted successfully',
      icon: Icons.check_circle_outline,
      color: Colors.green,
    );
  }

  // ============================================================
  // CAROUSEL
  // ============================================================

  PageController getCarouselPageController(String postId, int initialPage) {
    if (!_carouselPageControllers.containsKey(postId)) {
      final controller = PageController(initialPage: initialPage);

      _carouselPageControllers[postId] = controller;

      controller.addListener(() {
        if (!controller.hasClients) return;

        final page = controller.page;

        if (page == null) return;

        final currentPage = page;

        final intPage = currentPage.round();

        final fraction = currentPage - intPage;

        if (carouselIndexes[postId] != intPage) {
          carouselIndexes[postId] = intPage;
        }

        carouselScrollFractions[postId] = fraction;
      });
    }

    return _carouselPageControllers[postId]!;
  }

  // ============================================================
  // CLOSE
  // ============================================================

  @override
  void onClose() {
    debugPrint('[HOME] HomeController disposed');

    _newPostTimer?.cancel();
    _newPostTimer = null;

    scrollController.removeListener(_onScroll);
    scrollController.dispose();

    for (final controller in _carouselPageControllers.values) {
      controller.dispose();
    }

    _carouselPageControllers.clear();

    super.onClose();
  }
}
