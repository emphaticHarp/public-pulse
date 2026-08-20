import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:public_pulse/core/services/current_user_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String? webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
  String? get currentUserId => _supabase.auth.currentUser?.id;
  final String? androidClientId = dotenv.env['GOOGLE_ANDROID_CLIENT_ID'];

  late final GoogleSignIn _googleSignIn;

  StreamSubscription<AuthState>? _authSubscription;

  AuthService() {
    if (webClientId == null) {
      throw Exception("GOOGLE_WEB_CLIENT_ID is missing");
    }

    _googleSignIn = GoogleSignIn(clientId: webClientId);
  }

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        throw Exception("Google tokens are null");
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      return true;
    } catch (_) {
      return false;
    }
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

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      await _googleSignIn
          .signOut(); // fallback if disconnect fails (e.g. already signed out)
    }
    await _supabase.auth.signOut();
  }

  User? get currentUser {
    final user = _supabase.auth.currentUser;
    return user;
  }

  Map<String, dynamic>? get googleUserMetadata {
    final metadata = _supabase.auth.currentUser?.userMetadata;
    return metadata;
  }

  /// Get current logged-in user's profile
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return null;

    final profile = await _supabase
        .from('profiles')
        .select('*')
        .eq('user_id', user.id)
        .maybeSingle();

    if (profile != null) {
      final profileId = profile['id'] as String?;

      if (profileId != null) {
        CurrentUserService.instance.setProfileId(profileId);
      }
    }

    return profile;
  }

  Future<bool> verifyLoginCode(String code) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('user_id')
          .eq('refer_code', code)
          .maybeSingle();

      return profile != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> activateCurrentUser(String code) async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) return;

      await _supabase
          .from('profiles')
          .update({'status': 'active', 'login_code': code})
          .eq('user_id', user.id);
    } catch (_) {
      // Intentionally ignored.
    }
  }

  // // this function is used for if user is deleted from
  // Future<Map<String, dynamic>> createProfile() async {
  //   final user = _supabase.auth.currentUser!;

  //   // Check if profile already exists
  //   final existing = await _supabase
  //       .from('profiles')
  //       .select()
  //       .eq('user_id', user.id)
  //       .maybeSingle();

  //   if (existing != null) {
  //     return existing;
  //   }

  // //   // Create new profile
  // //   final profile = await _supabase
  // //       .from('profiles')
  // //       .insert({
  // //         'user_id': user.id,
  // //         'email': user.email,
  // //         'status': 'pending',
  // //         'display_name': user.userMetadata?['full_name'] ?? '',
  // //         'username': null, // You can set a default username or leave it null
  // //       })
  // //       .select()
  // //       .single();

  // //   return profile;
  // // }
}
