import 'package:get/get.dart';
import '../model/profile_model.dart';
import '../core/repository/profile_repository.dart';

class FollowersFollowingController extends GetxController {
  static FollowersFollowingController get to => Get.find();

  final ProfileRepository _repo = ProfileRepository.instance;

  final String userId;
  FollowersFollowingController({required this.userId});

  static const _pageSize = 20;

  // ── Tab ──────────────────────────────────────────────────────────────────

  final selectedTab = 0.obs;

  /// Switches the active tab and lazy-loads the first page if not yet fetched.
  void switchTab(int index) {
    selectedTab.value = index;
    if (index == 0 && !_followersLoaded) _loadFirstPage(isFollowers: true);
    if (index == 1 && !_followingLoaded) _loadFirstPage(isFollowers: false);
  }

  // ── Followers state ───────────────────────────────────────────────────────

  final followers = <FollowerModel>[].obs;
  final isLoadingFollowers = false.obs;
  final hasNextFollowers = false.obs;
  final hasPrevFollowers = false.obs;

  bool _followersLoaded = false;

  /// Cursor stack for followers backward navigation.
  /// Each entry is the `afterCursor` value that was used to fetch that page.
  /// null represents the first page (no cursor).
  final _followersCursorStack = <String?>[];

  /// The cursor used to fetch the *current* followers page (null = page 1).
  String? _followersCurrentCursor;

  // ── Following state ───────────────────────────────────────────────────────

  final following = <FollowerModel>[].obs;
  final isLoadingFollowing = false.obs;
  final hasNextFollowing = false.obs;
  final hasPrevFollowing = false.obs;

  bool _followingLoaded = false;

  /// Cursor stack for following backward navigation.
  final _followingCursorStack = <String?>[];

  /// The cursor used to fetch the *current* following page (null = page 1).
  String? _followingCurrentCursor;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    // Load whichever tab is shown first.
    _loadFirstPage(isFollowers: selectedTab.value == 0);
  }

  // ── Core fetch ────────────────────────────────────────────────────────────

  /// Fetches a page from the repository using [cursor] and updates state.
  Future<void> _fetchPage({
    required bool isFollowers,
    required String? cursor,
  }) async {
    final loading = isFollowers ? isLoadingFollowers : isLoadingFollowing;
    if (loading.value) return; // Guard: already fetching.

    loading(true);
    try {
      final data = isFollowers
          ? await _repo.getFollowers(userId, limit: _pageSize, afterCursor: cursor)
          : await _repo.getFollowing(userId, limit: _pageSize, afterCursor: cursor);

      // Replace the list with the new page's records.
      (isFollowers ? followers : following).assignAll(data);

      // Determine whether there is a next page by fetching one record beyond
      // the last one on this page.
      final hasNext = data.length == _pageSize;

      if (isFollowers) {
        hasNextFollowers(hasNext);
        hasPrevFollowers(_followersCursorStack.isNotEmpty);
        _followersLoaded = true;
      } else {
        hasNextFollowing(hasNext);
        hasPrevFollowing(_followingCursorStack.isNotEmpty);
        _followingLoaded = true;
      }
    } finally {
      loading(false);
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Loads the very first page (no cursor) for the given list.
  Future<void> _loadFirstPage({required bool isFollowers}) async {
    if (isFollowers) {
      _followersCursorStack.clear();
      _followersCurrentCursor = null;
    } else {
      _followingCursorStack.clear();
      _followingCurrentCursor = null;
    }
    await _fetchPage(isFollowers: isFollowers, cursor: null);
  }

  /// Loads the first page of followers (called from the view for initial load).
  Future<void> loadFollowers() => _loadFirstPage(isFollowers: true);

  /// Loads the first page of following (called from the view for initial load).
  Future<void> loadFollowing() => _loadFirstPage(isFollowers: false);

  /// Advances to the next page for [isFollowers] list.
  ///
  /// The last record on the current page becomes the new cursor.
  /// The *current* cursor is pushed onto the stack so we can go back.
  Future<void> nextPage({required bool isFollowers}) async {
    final list = isFollowers ? followers : following;
    if (list.isEmpty) return;

    final newCursor = list.last.userId;

    if (isFollowers) {
      _followersCursorStack.add(_followersCurrentCursor);
      _followersCurrentCursor = newCursor;
    } else {
      _followingCursorStack.add(_followingCurrentCursor);
      _followingCurrentCursor = newCursor;
    }

    await _fetchPage(isFollowers: isFollowers, cursor: newCursor);
  }

  /// Goes back to the previous page for [isFollowers] list.
  ///
  /// Pops the last cursor from the stack and re-fetches with it.
  Future<void> prevPage({required bool isFollowers}) async {
    final stack = isFollowers ? _followersCursorStack : _followingCursorStack;
    if (stack.isEmpty) return;

    final prevCursor = stack.removeLast();

    if (isFollowers) {
      _followersCurrentCursor = prevCursor;
    } else {
      _followingCurrentCursor = prevCursor;
    }

    await _fetchPage(isFollowers: isFollowers, cursor: prevCursor);
  }

  /// Clears all state and reloads the currently active tab from page 1.
  Future<void> refreshList() async {
    _followersLoaded = false;
    _followingLoaded = false;
    followers.clear();
    following.clear();
    hasNextFollowers(false);
    hasNextFollowing(false);
    hasPrevFollowers(false);
    hasPrevFollowing(false);
    await _loadFirstPage(isFollowers: selectedTab.value == 0);
  }

  /// Resets in-memory state so the next [switchTab] call re-fetches from scratch.
  void invalidateCache() {
    _followersLoaded = false;
    _followingLoaded = false;
    _followersCursorStack.clear();
    _followingCursorStack.clear();
    _followersCurrentCursor = null;
    _followingCurrentCursor = null;
    followers.clear();
    following.clear();
    hasNextFollowers(false);
    hasNextFollowing(false);
    hasPrevFollowers(false);
    hasPrevFollowing(false);
  }
}
