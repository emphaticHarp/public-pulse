# Cache Management & Home Page Code

---

## Cache Files

### `lib/core/cache/cache_keys.dart` — Key constants

```dart
class CacheKeys {
  static const String posts = 'posts';
  static const String timestamp = 'timestamp';
  static const String nextCursor = 'next_cursor';
  static const String hasMore = 'has_more';
}
```

### `lib/core/cache/hive_boxes.dart` — Box name constants

```dart
class HiveBoxes {
  static const cachedPosts = 'cached_posts';
  static const cachedProfiles = 'cached_profiles';
}
```

### `lib/core/cache/hive_service.dart` — Init Hive on app start

```dart
class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(HiveBoxes.cachedPosts);
    await Hive.openBox(HiveBoxes.cachedProfiles);
  }
}
```

### `lib/core/cache/cache_manager.dart` — All cache functions

```dart
class CacheManager {
  static Box get _postBox => Hive.box(HiveBoxes.cachedPosts);

  // SAVE posts to Hive cache
  static Future<void> cachePosts(
    List<PostModel> posts, {
    String? nextCursor,
    bool hasMore = true,
  }) async {
    final postsJson = posts.map((e) => e.toJson()).toList();
    await _postBox.put(CacheKeys.posts, postsJson);
    await _postBox.put(CacheKeys.timestamp, DateTime.now().millisecondsSinceEpoch);
    await _postBox.put(CacheKeys.nextCursor, nextCursor);
    await _postBox.put(CacheKeys.hasMore, hasMore);
  }

  // LOAD posts from Hive cache
  static List<PostModel> getCachedPosts() {
    final cached = _postBox.get(CacheKeys.posts);
    if (cached == null) return [];

    final List<PostModel> posts = [];
    for (int i = 0; i < cached.length; i++) {
      try {
        final postData = Map<String, dynamic>.from(cached[i]);
        posts.add(PostModel.fromCache(postData));
      } catch (e) {
        debugPrint('[DEBUG-CACHE] getCachedPosts: ERROR parsing post $i: $e');
      }
    }
    return posts;
  }

  // GET hasMore flag from cache
  static bool getHasMore() {
    return _postBox.get(CacheKeys.hasMore, defaultValue: true);
  }

  // GET pagination cursor from cache
  static String? getNextCursor() {
    return _postBox.get(CacheKeys.nextCursor);
  }

  // CLEAR all cached posts
  static Future<void> clearPostCache() async {
    await _postBox.clear();
  }
}
```

### `lib/model/post_model.dart` — Serialization for cache

```dart
// Converts PostModel to JSON (for saving to Hive)
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'profile_id': profileId,
    'username': username,
    'display_name': displayName,
    'profile_image': profileImage,
    'caption': caption,
    'location': location,
    'visibility': visibility,
    'is_private_account': isPrivateAccount,
    'storage_paths': storagePaths,
    'media_urls': mediaUrls,
    'thumbnail_urls': thumbnailUrls,
    'is_carousel': isCarousel,
    'like_count': likeCount,
    'comment_count': commentCount,
    'share_count': shareCount,
    'save_count': saveCount,
    'view_count': viewCount,
    'is_liked': isLiked,
    'is_saved': isSaved,
    'created_at': createdAt.toIso8601String(),
  };
}

// Rebuilds PostModel from Hive cache JSON
factory PostModel.fromCache(Map<String, dynamic> json) {
  return PostModel(
    id: json['id'],
    profileId: json['profile_id'],
    username: json['username'],
    displayName: json['display_name'],
    profileImage: json['profile_image'],
    caption: json['caption'],
    location: json['location'],
    visibility: json['visibility'],
    isPrivateAccount: json['is_private_account'],
    storagePaths: List<String>.from(json['storage_paths'] ?? []),
    mediaUrls: List<String>.from(json['media_urls'] ?? []),
    thumbnailUrls: List<String>.from(json['thumbnail_urls'] ?? []),
    isCarousel: json['is_carousel'],
    likeCount: json['like_count'],
    commentCount: json['comment_count'],
    shareCount: json['share_count'],
    saveCount: json['save_count'],
    viewCount: json['view_count'],
    isLiked: json['is_liked'] ?? false,
    isSaved: json['is_saved'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
  );
}
```

---

## Home Page Code

### `lib/view/home/home_page.dart` — Full UI

```dart
class HomePage extends StatelessWidget {
  HomePage({super.key});
  final HomeController controller = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NetworkWrapper(
        child: RefreshIndicator(
          onRefresh: controller.refreshFeed,
          color: AppColors.loginAccentRed,
          child: CustomScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(child: _buildHeader(context)),

              // Search Bar
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SearchBarWidget(),
                ),
              ),

              // New Posts Banner
              Obx(() {
                return SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: controller.newPostCount.value == 0
                        ? const SizedBox.shrink()
                        : Padding(
                            key: const ValueKey("new_posts_banner"),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8,
                            ),
                            child: GestureDetector(
                              onTap: () async {
                                await controller.refreshFeed();
                                if (controller.scrollController.hasClients) {
                                  controller.scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.loginAccentRed,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Center(
                                  child: Text(
                                    controller.newPostCount.value == 1
                                        ? "1 New Post"
                                        : "${controller.newPostCount.value} New Posts",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                );
              }),

              // Loading / Empty / Posts
              Obx(() {
                if (controller.isLoading.value) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.loginAccentRed,
                      ),
                    ),
                  );
                }

                if (controller.posts.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined,
                              size: 80, color: Colors.grey.shade400),
                          SizedBox(height: 18),
                          Text("No Posts Yet",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text("Posts from everyone will appear here.",
                              style: TextStyle(fontSize: 15, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= controller.posts.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.loginAccentRed,
                              ),
                            ),
                          );
                        }

                        final post = controller.posts[index];

                        return PostCard(
                          key: ValueKey(post.id),
                          profileImage: post.profileImage ?? '',
                          username: post.username,
                          location: post.location ?? '',
                          isCarousel: post.isCarousel,
                          imageUrl: post.mediaUrls.isNotEmpty
                              ? post.mediaUrls.first : null,
                          imageUrls: post.mediaUrls,
                          postId: post.isCarousel ? post.id : null,
                          likeIcon: post.isLiked
                              ? Icons.favorite : Icons.favorite_border,
                          likeIconColor: post.isLiked
                              ? AppColors.loginAccentRed : AppColors.gray900,
                          likeCount: post.likeCount.toString(),
                          commentCount: post.commentCount.toString(),
                          shareCount: post.shareCount.toString(),
                          caption: post.caption ?? '',
                          captionCommentCount: post.commentCount.toString(),
                          onLikeTap: () {
                            post.isLiked = !post.isLiked;
                            controller.posts.refresh();
                          },
                        );
                      },
                      childCount: controller.posts.length +
                          (controller.isLoadingMore.value ? 1 : 0),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: SizedBox(
              width: 42, height: 42,
              child: Transform.scale(
                scale: 3.5,
                child: Image.asset(
                  'assets/images/logo.webp',
                  width: 42, height: 42, fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.loginAccentRed, shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### `lib/controller/home_controller.dart` — Full controller

```dart
class HomeController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxMap<String, int> carouselIndexes = <String, int>{}.obs;
  final RxMap<String, double> carouselScrollFractions = <String, double>{}.obs;
  final Map<String, PageController> _carouselPageControllers = {};

  final PostRepository _repository = PostRepository();
  final RxList<PostModel> posts = <PostModel>[].obs;
  final RxList<PostModel> myPosts = <PostModel>[].obs;
  final isLoading = true.obs;
  String? nextCursor;
  final hasMore = true.obs;
  final isLoadingMore = false.obs;
  final RxList<PostModel> pendingPosts = <PostModel>[].obs;
  final RxInt newPostCount = 0.obs;
  Timer? _newPostTimer;
  final Set<String> _previouslyLoadedPostIds = {};

  @override
  void onInit() {
    super.onInit();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      loadCachedPosts();                    // ← reads from Hive first
      if (posts.isEmpty) {
        loadPosts();                        // ← fetch from Supabase if no cache
      } else {
        _startNewPostChecker();             // ← start 2-min timer if cache exists
      }
      loadMyPosts();
      scrollController.addListener(_onScroll);
    }
  }

  // CACHE: Load posts from Hive
  void loadCachedPosts() {
    final cachedPosts = CacheManager.getCachedPosts();  // ← reads from Hive
    if (cachedPosts.isEmpty) return;

    posts.assignAll(cachedPosts);
    nextCursor = CacheManager.getNextCursor();           // ← restores cursor
    hasMore.value = CacheManager.getHasMore();           // ← restores hasMore

    for (final p in cachedPosts) {
      _previouslyLoadedPostIds.add(p.id);
    }
    isLoading.value = false;
  }

  // SUPABASE: Fetch initial posts
  Future<void> loadPosts() async {
    try {
      if (posts.isEmpty) isLoading.value = true;
      final page = await _repository.getInitialPosts(limit: 10);  // ← Supabase SELECT
      nextCursor = page.nextCursor;
      hasMore.value = page.hasMore;
      posts.assignAll(page.posts);

      await CacheManager.cachePosts(posts,              // ← save to Hive
        nextCursor: nextCursor, hasMore: hasMore.value);

      if (_newPostTimer == null) _startNewPostChecker();
    } catch (e) { debugPrint('[ERROR] loadPosts: $e'); }
    finally { isLoading.value = false; }
  }

  // SUPABASE: Pull to refresh
  Future<void> refreshFeed() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final page = await _repository.getInitialPosts(limit: 10);
      nextCursor = page.nextCursor;
      hasMore.value = page.hasMore;

      final Map<String, PostModel> mergedMap = {};
      for (final post in page.posts) mergedMap[post.id] = post;
      for (final post in posts) mergedMap.putIfAbsent(post.id, () => post);
      posts.assignAll(mergedMap.values.toList());

      pendingPosts.clear();
      newPostCount.value = 0;

      await CacheManager.cachePosts(posts,               // ← save to Hive
        nextCursor: nextCursor, hasMore: hasMore.value);
    } catch (e) { debugPrint('[ERROR] refreshFeed: $e'); }
    finally { isLoading.value = false; }
  }

  // SUPABASE: Load more posts (pagination)
  Future<void> loadMorePosts() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final page = await _repository.getMorePosts(cursor: nextCursor!, limit: 10);
      nextCursor = page.nextCursor;
      hasMore.value = page.hasMore;

      final existingIds = posts.map((e) => e.id).toSet();
      for (final post in page.posts) {
        if (!existingIds.contains(post.id)) posts.add(post);
      }

      await CacheManager.cachePosts(posts,               // ← save to Hive
        nextCursor: nextCursor, hasMore: hasMore.value);
    } catch (e) { debugPrint('[ERROR] loadMorePosts: $e'); }
    finally { isLoadingMore.value = false; }
  }

  // Timer: check for new posts every 2 minutes
  void _startNewPostChecker() {
    _newPostTimer?.cancel();
    _newPostTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      if (Get.currentRoute != '/home') return;
      await _checkForNewPosts();
    });
  }

  // SUPABASE: Poll for new posts
  Future<void> _checkForNewPosts() async {
    try {
      if (isLoading.value || isLoadingMore.value || posts.isEmpty) return;
      final latestCreatedAt = posts.first.createdAt.toIso8601String();
      final newPosts = await _repository.getNewPosts(latestCreatedAt: latestCreatedAt);
      if (newPosts.isEmpty) return;

      for (final post in newPosts) {
        if (!pendingPosts.any((e) => e.id == post.id)) pendingPosts.add(post);
      }
      newPostCount.value = pendingPosts.length;
    } catch (e) { debugPrint('[ERROR] _checkForNewPosts: $e'); }
  }

  // Scroll listener: trigger loadMore when near bottom
  void _onScroll() {
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      loadMorePosts();
    }
  }

  // Load user's own posts
  Future<void> loadMyPosts() async {
    try {
      final fetchedPosts = await _repository.getMyPosts();
      myPosts.assignAll(fetchedPosts);
    } catch (e) { debugPrint('[ERROR] loadMyPosts: $e'); }
  }

  final ScrollController scrollController = ScrollController();

  @override
  void onClose() {
    scrollController.dispose();
    for (final pc in _carouselPageControllers.values) pc.dispose();
    _carouselPageControllers.clear();
    _newPostTimer?.cancel();
    super.onClose();
  }

  PageController getCarouselPageController(String postId, int initialPage) {
    if (!_carouselPageControllers.containsKey(postId)) {
      final pc = PageController(initialPage: initialPage);
      _carouselPageControllers[postId] = pc;
      pc.addListener(() {
        if (pc.hasClients && pc.page != null) {
          final currentPage = pc.page!;
          carouselIndexes[postId] = currentPage.round();
          carouselScrollFractions[postId] = currentPage - currentPage.round();
        }
      });
    }
    return _carouselPageControllers[postId]!;
  }
}
```

---

## Function → What It Does → Where It's Called

| Function | File | What It Does | Called By |
|----------|------|-------------|-----------|
| `HiveService.init()` | `hive_service.dart` | Opens Hive boxes at app start | `main.dart` |
| `CacheManager.cachePosts()` | `cache_manager.dart` | Saves posts + cursor + hasMore to Hive | `loadPosts()`, `refreshFeed()`, `loadMorePosts()` |
| `CacheManager.getCachedPosts()` | `cache_manager.dart` | Reads posts from Hive, returns `List<PostModel>` | `loadCachedPosts()` |
| `CacheManager.getHasMore()` | `cache_manager.dart` | Reads `hasMore` flag from Hive | `loadCachedPosts()` |
| `CacheManager.getNextCursor()` | `cache_manager.dart` | Reads pagination cursor from Hive | `loadCachedPosts()` |
| `CacheManager.clearPostCache()` | `cache_manager.dart` | Wipes all cached posts | (available, not called in prod) |
| `PostModel.toJson()` | `post_model.dart` | Serializes a post to JSON map for Hive storage | `CacheManager.cachePosts()` |
| `PostModel.fromCache()` | `post_model.dart` | Deserializes JSON map back to `PostModel` | `CacheManager.getCachedPosts()` |
| `loadCachedPosts()` | `home_controller.dart` | Reads cache → sets posts, cursor, hasMore, hides loader | `onInit()` |
| `loadPosts()` | `home_controller.dart` | Fetches from Supabase → saves to cache | `onInit()` when cache is empty |
| `refreshFeed()` | `home_controller.dart` | Re-fetches from Supabase → merges → saves to cache | Pull-to-refresh, new posts banner tap |
| `loadMorePosts()` | `home_controller.dart` | Fetches next page from Supabase → appends → saves to cache | Scroll near bottom |
| `_checkForNewPosts()` | `home_controller.dart` | Polls Supabase for newer posts every 2 min | `_startNewPostChecker()` timer |
| `loadMyPosts()` | `home_controller.dart` | Fetches user's own posts from Supabase | `onInit()` |
