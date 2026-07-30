import 'package:public_pulse/model/post_model.dart';

class TimelineCache {
  final List<PostModel> posts;
  final String? nextCursor;
  final bool hasMore;
  final DateTime cachedAt;

  TimelineCache({
    required this.posts,
    required this.cachedAt,
    this.nextCursor,
    this.hasMore = true,
  });
}