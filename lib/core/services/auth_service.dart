import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String? webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
String? get currentUserId => _supabase.auth.currentUser?.id;
  final String? androidClientId = dotenv.env['GOOGLE_ANDROID_CLIENT_ID'];

  late final GoogleSignIn _googleSignIn;

  StreamSubscription<AuthState>? _authSubscription;

  AuthService() {
    debugPrint("AuthService: constructor called");
    debugPrint("AuthService: webClientId present = ${webClientId != null}");
    debugPrint(
      "AuthService: androidClientId present = ${androidClientId != null}",
    );

    if (webClientId == null) {
      debugPrint("AuthService ERROR: GOOGLE_WEB_CLIENT_ID is missing");
      throw Exception("GOOGLE_WEB_CLIENT_ID is missing");
    }

    _googleSignIn = GoogleSignIn(clientId: webClientId);
    debugPrint("AuthService: GoogleSignIn initialized");
  }

  Future<bool> signInWithGoogle() async {
    debugPrint("signInWithGoogle: starting Google sign-in flow");
    try {
      debugPrint("signInWithGoogle: invoking _googleSignIn.signIn()");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint(
          "signInWithGoogle: user cancelled sign-in (googleUser == null)",
        );
        return false;
      }

      debugPrint(
        "signInWithGoogle: googleUser obtained -> email=${googleUser.email}, id=${googleUser.id}",
      );

      debugPrint("signInWithGoogle: fetching authentication tokens");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint(
        "signInWithGoogle: idToken present = ${googleAuth.idToken != null}, "
        "accessToken present = ${googleAuth.accessToken != null}",
      );

      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        debugPrint("signInWithGoogle ERROR: Google tokens are null");
        throw Exception("Google tokens are null");
      }

      debugPrint("signInWithGoogle: signing in to Supabase with idToken");
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      debugPrint("signInWithGoogle: Supabase sign-in successful");
      return true;
    } catch (e, stackTrace) {
      final errorMessage = "Google Sign-In Error: $e";
      debugPrint(errorMessage);
      debugPrint("signInWithGoogle: stackTrace = $stackTrace");
      debugPrint(errorMessage);
      return false;
    }
  }

  void listenToAuthChanges({
    required Future<void> Function(User user) onSignedIn,
  }) {
    debugPrint("listenToAuthChanges: subscribing to auth state changes");
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      debugPrint("listenToAuthChanges: event received -> $event");
      debugPrint(
        "listenToAuthChanges: session user present = ${session?.user != null}",
      );

      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        debugPrint(
          "listenToAuthChanges: signedIn event detected, invoking onSignedIn callback for user=${session!.user.id}",
        );
        await onSignedIn(session.user);
        debugPrint("listenToAuthChanges: onSignedIn callback completed");
      }
    });
    debugPrint("listenToAuthChanges: subscription established");
  }

  void dispose() {
    debugPrint("dispose: cancelling auth subscription");
    _authSubscription?.cancel();
    debugPrint("dispose: auth subscription cancelled");
  }

  Future<void> signOut() async {
    debugPrint("signOut: starting sign-out flow");
    try {
      debugPrint("signOut: attempting googleSignIn.disconnect()");
      await _googleSignIn.disconnect();
      debugPrint("signOut: googleSignIn.disconnect() succeeded");
    } catch (e) {
      debugPrint(
        "signOut: disconnect() failed ($e), falling back to signOut()",
      );
      await _googleSignIn
          .signOut(); // fallback if disconnect fails (e.g. already signed out)
      debugPrint("signOut: googleSignIn.signOut() fallback completed");
    }
    debugPrint("signOut: signing out of Supabase");
    await _supabase.auth.signOut();
    debugPrint("signOut: Supabase sign-out completed");
  }

  User? get currentUser {
    final user = _supabase.auth.currentUser;
    debugPrint("currentUser: accessed -> ${user?.id ?? 'null'}");
    return user;
  }

  Map<String, dynamic>? get googleUserMetadata {
    final metadata = _supabase.auth.currentUser?.userMetadata;
    debugPrint("googleUserMetadata: accessed -> $metadata");
    return metadata;
  }

  /// Get current logged-in user's profile
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      final user = _supabase.auth.currentUser;

      debugPrint("Current User ID: ${user?.id}");
      debugPrint("Current User Email: ${user?.email}");

      final result = await _supabase.from('profiles').select('*');

      debugPrint("Profiles returned: $result");

      final profile = await _supabase
          .from('profiles')
          .select('*')
          .eq('user_id', user!.id)
          .maybeSingle();

      debugPrint("Profile found: $profile");

      return profile;
    } catch (e) {
      debugPrint("getCurrentProfile ERROR: $e");
      return null;
    }
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
      debugPrint("verifyLoginCode ERROR: $e");
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
    } catch (e) {
      debugPrint("activateCurrentUser ERROR: $e");
    }
  }
}
