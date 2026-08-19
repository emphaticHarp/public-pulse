import 'package:get/get.dart';
import 'package:public_pulse/model/notification_model.dart';
import 'package:public_pulse/core/repository/notification_repository.dart';
import 'package:public_pulse/widget/local/app_alerts.dart';

class NotificationController extends GetxController {
  // ==========================================================
  // TAB
  // ==========================================================

  final RxInt tabIndex = 0.obs;

  // ==========================================================
  // NOTIFICATIONS
  // ==========================================================

  final RxList<NotificationModel> newNotifications = <NotificationModel>[].obs;

  final RxList<NotificationModel> earlierNotifications =
      <NotificationModel>[].obs;

  final List<NotificationModel> _allNotifications = <NotificationModel>[];

  // ==========================================================
  // STATE
  // ==========================================================

  final RxBool isLoading = false.obs;

  final RxString errorMessage = ''.obs;

  final NotificationRepository _repository = NotificationRepository();

  bool get hasNoNotifications =>
      newNotifications.isEmpty && earlierNotifications.isEmpty;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void onInit() {
    super.onInit();

    ever<int>(tabIndex, (_) => _applyFilter());

    fetchNotifications();
  }

  // ==========================================================
  // FETCH
  // ==========================================================

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final notifications = await _repository.getNotifications();

      _allNotifications
        ..clear()
        ..addAll(notifications);

      // Always newest first.
      _allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _applyFilter();
    } catch (e) {
      errorMessage.value = 'Failed to load notifications';
    } finally {
      isLoading.value = false;
    }
  }

  // ==========================================================
  // FILTER
  // ==========================================================

  void _applyFilter() {
    final now = DateTime.now();

    // Start with ALL notifications.
    List<NotificationModel> filtered = List<NotificationModel>.from(
      _allNotifications,
    );

    switch (tabIndex.value) {
      case 1: // Likes
        filtered = filtered
            .where(
              (n) => n.notificationType.trim().toUpperCase() == 'POST_LIKE',
            )
            .toList();
        break;

      case 2: // Comments
        filtered = filtered
            .where(
              (n) => n.notificationType.trim().toUpperCase() == 'POST_COMMENT',
            )
            .toList();
        break;

      case 3: // Follows
        filtered = filtered
            .where(
              (n) => n.notificationType.trim().toUpperCase() == 'FOLLOW',
            )
            .toList();
        break;

      default: // All
        break;
    }

    // Sort newest -> oldest.
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // New = less than 24 hours old.
    final newItems = filtered.where((n) {
      return now.difference(n.createdAt).inHours < 24;
    }).toList();

    // Earlier = 24 hours or older.
    final earlierItems = filtered.where((n) {
      return now.difference(n.createdAt).inHours >= 24;
    }).toList();

    newNotifications.assignAll(newItems);
    earlierNotifications.assignAll(earlierItems);
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }

  Future<void> followBack(String actorProfileId) async {
    try {
      await _repository.followBack(actorProfileId);

      await fetchNotifications();
    } catch (e, stackTrace) {
      CustomAlert.error(
        title: 'Follow failed',
        message: 'Unable to follow this user. Please try again.',
      );
    }
  }
}
