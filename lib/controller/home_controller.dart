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

  final RxList<PostModel> posts = <PostModel>[].obs;

  @override
  void onInit() {
    super.onInit();

    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      debugPrint('[DEBUG-CONTROLLER] User logged in, loading posts');
      loadPosts();
    } else {
      debugPrint('[DEBUG-CONTROLLER] User not logged in, skipping loadPosts()');
    }
  }

  Future<void> loadMyPosts() async {
    final fetchedPosts = await _repository.getMyPosts();
    posts.assignAll(fetchedPosts);
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
    debugPrint('[DEBUG-CONTROLLER] loadPosts: starting...');
    try {
      final fetchedPosts = await _repository.getPosts();
      debugPrint(
        '[DEBUG-CONTROLLER] loadPosts: received ${fetchedPosts.length} posts from repository',
      );
      posts.assignAll(fetchedPosts);
      debugPrint(
        '[DEBUG-CONTROLLER] loadPosts: posts list updated, current length = ${posts.length}',
      );
    } catch (e, stackTrace) {
      debugPrint('[DEBUG-CONTROLLER] loadPosts: ERROR = $e');
      debugPrint('[DEBUG-CONTROLLER] loadPosts: stackTrace = $stackTrace');
    }
  }
}
