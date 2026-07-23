import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/model/post_model.dart';

class HomeController extends GetxController {
  final RxInt currentIndex = 0.obs;

  /// Per-post carousel index: postId -> current page index
  final RxMap<String, int> carouselIndexes = <String, int>{}.obs;

  /// Per-post fractional scroll position for smooth dot animations
  final RxMap<String, double> carouselScrollFractions = <String, double>{}.obs;

  /// Per-post PageControllers for carousel posts
  final Map<String, PageController> _carouselPageControllers = {};

  final RxList<PostModel> posts = <PostModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDummyPosts();
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

  void loadDummyPosts() {
    posts.value = [
      PostModel(
        id: '1',

        profileImage:
            'https://png.pngtree.com/png-clipart/20230927/original/pngtree-man-avatar-image-for-profile-png-image_13001882.png',

        username: 'Arjun Verma',
        location: 'Kolkata, West Bengal',
        isCarousel: false,
        imageUrl:
            'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',

        isLiked: false,
        likeCount: '1.2K',

        commentCount: '67',

        shareCount: '143',

        caption: 'Beautiful sunset at the park! 🌅',

        captionCommentCount: '67',
      ),

      PostModel(
        id: '2',

        profileImage:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCRXrg8jv_gNbpxWTbHTcNYIqrKteX-noCsBjI941TQnrw4dosFG6tH3B9Qj6pEB2oZc0WAlKvLcZorPKwhV1RhCromszfTMiJJ1oYwRPicmvQaG0DVBAozvRFExhzwXOJM6g5gzejjYPXvBdAPwyUmS1CKC1bebShXLzbRdirWYQML71msgzeBNVp9uBR5c2PBDbpDqp7KgwkWxH2xlb4bxjF0ZVuMAVqIiNQ0wgVxW90kXYc8qjw9_sJKGhS79sNGMaMeLgY8o1jV',

        username: 'Sneha Das',
        location: 'Mumbai, Maharashtra',
        isCarousel: true,

        imageUrls: [
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',

          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800',

          'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=800',

          'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=800',

          'https://images.unsplash.com/photo-1433086966358-54859d0ed716?w=800',
        ],

        isLiked: false,
        likeCount: '856',

        commentCount: '42',

        shareCount: '98',

        caption: 'Exploring the mountains today! 🏔️',

        captionCommentCount: '42',
      ),
    ];

    // Initialize per-post carousel indexes for carousel posts
    for (final post in posts) {
      if (post.isCarousel) {
        carouselIndexes[post.id] = 0;
      }
    }
  }
}
