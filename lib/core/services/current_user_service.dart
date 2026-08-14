import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CurrentUserService {
  CurrentUserService._();

  static final CurrentUserService instance = CurrentUserService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  String? _profileId;

  /// Auth user ID that owns the cached profile ID.
  String? _cachedAuthUserId;

  String? get profileId => _profileId;

  // ============================================================
  // SET PROFILE ID
  // ============================================================

  void setProfileId(String profileId) {
    final currentAuthUserId = _supabase.auth.currentUser?.id;

    _profileId = profileId;
    _cachedAuthUserId = currentAuthUserId;

    debugPrint('[CURRENT USER] Profile ID cached: $_profileId');

    debugPrint('[CURRENT USER] Cached auth user: $_cachedAuthUserId');
  }

  // ============================================================
  // GET PROFILE ID
  // ============================================================

  Future<String?> getProfileId() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      debugPrint('[CURRENT USER] No authenticated user');

      clear();

      return null;
    }

    // ============================================================
    // USE CACHE ONLY IF IT BELONGS TO THIS AUTH USER
    // ============================================================

    if (_profileId != null && _cachedAuthUserId == user.id) {
      debugPrint('[CURRENT USER] Using cached profile ID: $_profileId');

      return _profileId;
    }

    // ============================================================
    // AUTH USER CHANGED
    // ============================================================

    if (_cachedAuthUserId != null && _cachedAuthUserId != user.id) {
      debugPrint(
        '[CURRENT USER] Auth user changed. Clearing old profile cache.',
      );

      _profileId = null;
      _cachedAuthUserId = null;
    }

    // ============================================================
    // LOAD CURRENT USER PROFILE ID
    // ============================================================

    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      final loadedProfileId = response?['id']?.toString();

      if (loadedProfileId == null) {
        debugPrint(
          '[CURRENT USER] Profile row not found for auth user: ${user.id}',
        );

        clear();

        return null;
      }

      _profileId = loadedProfileId;
      _cachedAuthUserId = user.id;

      debugPrint('[CURRENT USER] Profile ID loaded: $_profileId');

      debugPrint('[CURRENT USER] Auth user: ${user.id}');

      return _profileId;
    } catch (e, stackTrace) {
      debugPrint('[CURRENT USER] Failed to load profile ID: $e');

      debugPrintStack(stackTrace: stackTrace);

      return null;
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    debugPrint('[CURRENT USER] Clearing cached profile ID');

    _profileId = null;
    _cachedAuthUserId = null;
  }
}
