import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSubscription;

  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(OAuthProvider.google);
  }

  void listenToAuthChanges({
    required Future<void> Function(User user) onSignedIn,
  }) {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        await onSignedIn(session!.user);
      }
    });
  }

  void dispose() {
    _authSubscription?.cancel();
  }

  Future<bool> userExists() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    final email = user.email;

    if (email == null) {
      return false;
    }

    final response = await _supabase
        .from('profiles')
        .select('email')
        .eq('email', email)
        .maybeSingle();

    return response != null;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser {
    return _supabase.auth.currentUser;
  }
}
