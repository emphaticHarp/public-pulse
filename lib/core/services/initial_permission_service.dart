import 'package:shared_preferences/shared_preferences.dart';
import 'package:public_pulse/core/services/permission_service.dart';

class InitialPermissionService {
  InitialPermissionService._();

  // ============================================================
  // KEYS
  // ============================================================

  static String _requiredKey(String userId) {
    return 'initial_permissions_required_$userId';
  }

  static String _completedKey(String userId) {
    return 'initial_permissions_completed_$userId';
  }

  // ============================================================
  // MARK NEW USER
  // ============================================================

  static Future<void> markNewUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    final completed = prefs.getBool(_completedKey(userId)) ?? false;

    if (completed) {
      return;
    }

    await prefs.setBool(_requiredKey(userId), true);
  }

  // ============================================================
  // REQUEST IF NEEDED
  // ============================================================

  static Future<void> requestIfNeeded(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    final required = prefs.getBool(_requiredKey(userId)) ?? false;

    final completed = prefs.getBool(_completedKey(userId)) ?? false;

    // Existing user / already completed.
    if (!required || completed) {
      return;
    }

    // Ask Android permissions.
    await PermissionService.requestInitialPermissions();

    // Important:
    // Mark completed even if user denied one permission.
    // We don't want to ask ALL permissions every login.
    await prefs.setBool(_completedKey(userId), true);

    await prefs.setBool(_requiredKey(userId), false);
  }
}
