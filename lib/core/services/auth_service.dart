import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<UserCredential?> signInWithGoogle() async {
    // Initialize Google Sign-In
    await _googleSignIn.initialize();

    // Show Google account picker
    final GoogleSignInAccount googleUser =
        await _googleSignIn.authenticate();

    // Get Google authentication tokens
    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    // Create Firebase credential
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Sign into Firebase
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}