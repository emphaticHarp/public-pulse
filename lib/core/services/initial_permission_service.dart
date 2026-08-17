import 'package:flutter/foundation.dart';
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
      debugPrint('[PERMISSIONS] Initial permissions already completed');
      return;
    }

    await prefs.setBool(_requiredKey(userId), true);

    debugPrint('[PERMISSIONS] New user marked for initial permissions');
  }

  // ============================================================
  // REQUEST IF NEEDED
  // ============================================================

  static Future<void> requestIfNeeded(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    final required = prefs.getBool(_requiredKey(userId)) ?? false;

    final completed = prefs.getBool(_completedKey(userId)) ?? false;

    debugPrint('[PERMISSIONS] required=$required completed=$completed');

    // Existing user / already completed.
    if (!required || completed) {
      debugPrint('[PERMISSIONS] Initial permission flow skipped');

      return;
    }

    debugPrint('[PERMISSIONS] Starting initial permission flow');

    // Ask Android permissions.
    await PermissionService.requestInitialPermissions();

    // Important:
    // Mark completed even if user denied one permission.
    // We don't want to ask ALL permissions every login.
    await prefs.setBool(_completedKey(userId), true);

    await prefs.setBool(_requiredKey(userId), false);

    debugPrint('[PERMISSIONS] Initial permission flow completed');
  }
}
