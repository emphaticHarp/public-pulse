import 'dart:async';

import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/model/pending_media.dart';

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

    initializeForUser();
  }

  void resetForLogout() {
    debugPrint('[HOME] Resetting HomeController for logout');

    currentIndex.value = 0;

    posts.clear();
    myPosts.clear();
    followingIds.clear();

    pendingPosts.clear();
    newPostCount.value = 0;

    nextCursor = null;
    hasMore.value = true;

    carouselIndexes.clear();
    carouselScrollFractions.clear();

    _previouslyLoadedPostIds.clear();

    isLoading.value = false;
    isLoadingMore.value = false;

    debugPrint('[HOME] HomeController reset complete');
  }

  // ============================================================
  // HOME INITIALIZATION
  // ============================================================

  Future<void> initializeForUser() async {
    debugPrint('[HOME] ===== INITIALIZING FOR CURRENT USER =====');

    isLoading.value = true;

    try {
      // ============================================================
      // CURRENT USER
      // ============================================================

      final currentProfileId = await _repository.getCurrentProfileId();

      if (currentProfileId == null) {
        debugPrint('[HOME] No current profile ID');

        posts.clear();

        return;
      }

      // ============================================================
      // CHECK WHO OWNS THE CACHED FEED
      // ============================================================

      final cachedOwner = CacheManager.getPostCacheOwnerProfileId();

      final hasCachedFeed = CacheManager.hasPostCache();

      debugPrint('[HOME] Current profile: $currentProfileId');

      debugPrint('[HOME] Cached feed owner: $cachedOwner');

      // ============================================================
      // DIFFERENT USER / OLD LEGACY CACHE
      // ============================================================

      if (hasCachedFeed && cachedOwner != currentProfileId) {
        debugPrint('[HOME] Different cache owner detected');

        debugPrint('[HOME] Clearing previous user feed cache');

        await CacheManager.clearPostCache();

        posts.clear();

        nextCursor = null;
        hasMore.value = true;

        _previouslyLoadedPostIds.clear();
      }

      // ============================================================
      // MARK CACHE AS BELONGING TO CURRENT USER
      // ============================================================

      await CacheManager.setPostCacheOwnerProfileId(currentProfileId);

      // ============================================================
      // LOAD CACHE
      // ============================================================

      loadCachedPosts();

      // ============================================================
      // NO VALID CACHE → SERVER
      // ============================================================

      if (posts.isEmpty) {
        debugPrint('[HOME] No valid cache → fetching from server');

        await loadPosts();
      } else {
        debugPrint('[HOME] Valid cache belongs to current user');
      }

      // ============================================================
      // OTHER USER DATA
      // ============================================================

      await Future.wait([loadMyPosts(), loadFollowingIds()]);

      debugPrint('[HOME] ===== USER INITIALIZATION COMPLETE =====');
    } catch (e, stackTrace) {
      debugPrint('[HOME] initializeForUser error: $e');

      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
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

      // Server response is authoritative.
      posts.assignAll(page.posts);

      _previouslyLoadedPostIds
        ..clear()
        ..addAll(page.posts.map((post) => post.id));

      debugPrint('[HOME] Feed updated from server');
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

  Future<bool> refreshFeed() async {
    if (isLoading.value) return false;

    debugPrint('[HOME] ===============================');
    debugPrint('[HOME] MANUAL REFRESH');
    debugPrint('[HOME] ===============================');

    isLoading.value = true;

    try {
      final page = await _repository.getInitialPosts(limit: 10);

      nextCursor = page.nextCursor;
      hasMore.value = page.hasMore;

      _logPostSource('[SUPABASE] Manual refresh', page.posts);

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

      debugPrint('[HOME] Refresh complete → ${posts.length} posts');

      return true;
    } catch (e, stackTrace) {
      debugPrint('[HOME] refreshFeed error: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
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
        followingIds.assignAll(cached);

        debugPrint('[FOLLOW] Loaded ${cached.length} IDs from cache');
      }

      // ----------------------------------------------------------
      // Server refresh.
      // ----------------------------------------------------------

      final server = await FollowRepository.instance.getFollowingIds();

      followingIds.assignAll(server);

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
        color: AppColors.loginAccentRed,
      );

      return;
    }

    CustomAlert.show(
      title: 'Deleted',
      message: 'Post deleted successfully',
      icon: Icons.check_circle_outline,
      color: AppColors.semanticGreen,
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

        final intPage = currentPage.floor();

        final fraction = currentPage - intPage;

        if (carouselIndexes[postId] != intPage) {
          carouselIndexes[postId] = intPage;
        }

        carouselScrollFractions[postId] = fraction;
      });
    }

    return _carouselPageControllers[postId]!;
  }

  String addUploadingPost({
    required List<PendingMedia> mediaSnapshot,
    required String? caption,
    required String? location,
    required String visibility,
  }) {
    final tempPostId = 'uploading_${DateTime.now().millisecondsSinceEpoch}';

    final tempPost = PostModel(
      id: tempPostId,

      profileId: '',
      username: 'You',
      displayName: 'You',
      profileImage: null,

      caption: caption,
      location: location,

      visibility: visibility,
      isPrivateAccount: false,
      isOwner: true,

      storagePaths: const [],
      mediaUrls: const [],
      thumbnailUrls: const [],
      isCarousel: mediaSnapshot.length > 1,

      // Temporary uploading posts use local files.
      // Real aspect ratios will arrive after the uploaded post
      // is fetched back from Supabase.
      mediaAspectRatios: const [],

      likeCount: 0,
      commentCount: 0,
      shareCount: 0,
      saveCount: 0,
      viewCount: 0,

      isLiked: false,
      isSaved: false,

      localMediaPaths: mediaSnapshot
          .map((media) => media.originalPath)
          .toList(),

      isUploading: true,
      uploadFailed: false,

      createdAt: DateTime.now(),
    );

    posts.insert(0, tempPost);
    posts.refresh();

    debugPrint('[HOME] Temporary uploading post added: $tempPostId');

    return tempPostId;
  }

  void removeUploadingPost(String tempPostId) {
    posts.removeWhere((post) => post.id == tempPostId);

    posts.refresh();

    debugPrint('[HOME] Temporary uploading post removed: $tempPostId');
  }

  void markUploadingPostFailed(String tempPostId) {
    final index = posts.indexWhere((post) => post.id == tempPostId);

    if (index == -1) return;

    posts[index].isUploading = false;
    posts[index].uploadFailed = true;

    posts.refresh();

    debugPrint('[HOME] Upload failed: $tempPostId');
  }
  // ============================================================
  // CLOSE
  // ============================================================

  @override
  void onClose() {
    debugPrint('[HOME] HomeController disposed');

    scrollController.removeListener(_onScroll);
    scrollController.dispose();

    for (final controller in _carouselPageControllers.values) {
      controller.dispose();
    }

    _carouselPageControllers.clear();

    super.onClose();
  }
}
