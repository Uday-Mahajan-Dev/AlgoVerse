import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/network/api_client.dart';

class SocialAuthService {
  SocialAuthService._();

  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // ============================================================
  // GOOGLE
  // ============================================================

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    await _googleSignIn.initialize();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);

    return _sendFirebaseUserToBackend(userCredential.user);
  }

  // ============================================================
  // GITHUB
  // ============================================================

  static Future<Map<String, dynamic>> signInWithGitHub() async {
    final provider = GithubAuthProvider();

    final userCredential = await _firebaseAuth.signInWithProvider(provider);

    return _sendFirebaseUserToBackend(userCredential.user);
  }

  // ============================================================
  // FIREBASE → FASTAPI
  // ============================================================

  static Future<Map<String, dynamic>> _sendFirebaseUserToBackend(
    User? user,
  ) async {
    if (user == null) {
      throw Exception('Authentication failed. Please try again.');
    }

    final firebaseIdToken = await user.getIdToken();

    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw Exception('Failed to obtain Firebase ID token.');
    }

    return ApiClient.socialLogin(firebaseIdToken);
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  static Future<void> signOut() async {
    await _firebaseAuth.signOut();

    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google may not have been used.
    }
  }
}
