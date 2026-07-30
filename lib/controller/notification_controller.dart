import 'package:get/get.dart';
import 'package:public_pulse/model/notification_model.dart';
import 'package:public_pulse/core/repository/notification_repository.dart';

class NotificationController extends GetxController {
  /// Selected notification tab
  final RxInt tabIndex = 0.obs;

  /// New notifications
  final RxList<NotificationModel> newNotifications = <NotificationModel>[].obs;

  /// Earlier notifications
  final RxList<NotificationModel> earlierNotifications =
      <NotificationModel>[].obs;

  // Connects the controller to the notification repository.
  final NotificationRepository _repository = NotificationRepository();

  // Shows loading while notifications are being fetched.
  final RxBool isLoading = false.obs;

  // Stores all notifications before applying any filters.
  final List<NotificationModel> _allNotifications = [];

  // Indicates whether loading notifications failed.
  final RxString errorMessage = ''.obs;

  // Returns true when there are no notifications to display.
  bool get hasNoNotifications =>
      newNotifications.isEmpty && earlierNotifications.isEmpty;

  @override
  void onInit() {
    super.onInit();

    // Re-filters notifications whenever the selected tab changes.
    ever(tabIndex, (_) => _applyFilter());

    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final notifications = await _repository.getNotifications();

      _allNotifications
        ..clear()
        ..addAll(notifications);

      _applyFilter();
    } catch (e) {
      errorMessage.value = "Failed to load notifications";
    } finally {
      isLoading.value = false;
    }
  }

  // Filters notifications based on the selected tab and groups them into New and Earlier.
  void _applyFilter() {
    final now = DateTime.now();

    List<NotificationModel> filtered = _allNotifications;

    switch (tabIndex.value) {
      case 1: // Likes
        filtered = filtered.where((n) {
          return n.notificationType == 'LIKE';
        }).toList();
        break;

      case 2: // Comments
        filtered = filtered.where((n) {
          return n.notificationType == 'COMMENT';
        }).toList();
        break;

      case 3: // Follows
        filtered = filtered.where((n) {
          return n.notificationType == 'FOLLOW';
        }).toList();
        break;

      default:
        break;
    }

    newNotifications.assignAll(
      filtered.where((n) {
        return now.difference(n.createdAt).inHours < 24;
      }).toList(),
    );

    earlierNotifications.assignAll(
      filtered.where((n) {
        return now.difference(n.createdAt).inHours >= 24;
      }).toList(),
    );
  }
}
