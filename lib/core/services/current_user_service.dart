import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CurrentUserService {
  CurrentUserService._();

  void setProfileId(String profileId) {
    _profileId = profileId;
  }

  static final CurrentUserService instance = CurrentUserService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  String? _profileId;

  String? get profileId => _profileId;

 Future<String?> getProfileId() async {
  if (_profileId != null) {
    return _profileId;
  }

  final user = _supabase.auth.currentUser;

  if (user == null) {
    return null;
  }

  try {
    final response = await _supabase
        .from('profiles')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    _profileId = response?['id'] as String?;

    debugPrint('[CURRENT USER] Profile user_id loaded: $_profileId');

    return _profileId;
  } catch (e, stackTrace) {
    debugPrint('[CURRENT USER] Failed to load profile user_id: $e');
    debugPrintStack(stackTrace: stackTrace);
    return null;
  }
}

  void clear() {
    _profileId = null;
  }
}
