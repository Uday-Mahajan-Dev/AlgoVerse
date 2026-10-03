import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class SocialAuthService {
  static final SocialAuthService _instance = SocialAuthService._();
  factory SocialAuthService() => _instance;
  SocialAuthService._();

  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static GoogleSignIn? _googleSignInInstance;

  static GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= GoogleSignIn.instance;
    return _googleSignInInstance!;
  }

  // Web / Server Client ID from google-services.json (client_type 3)
  static const String _serverClientId =
      '1006860409119-igrfiq3fd85bbqs74d9n9hfme0vn0lu6.apps.googleusercontent.com';

  // ============================================================
  // GOOGLE
  // ============================================================

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    if (kIsWeb) {
      throw Exception(
        'Social login on Web is in preview. Please log in using your Email & Password.',
      );
    }

    try {
      debugPrint('[GoogleSignIn] Starting Google Sign-In flow...');
      debugPrint('[GoogleSignIn] Initializing GoogleSignIn with serverClientId: $_serverClientId');

      await _googleSignIn.initialize(serverClientId: _serverClientId);

      debugPrint('[GoogleSignIn] Opening account picker...');
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      debugPrint(
        '[GoogleSignIn] Account selected: ${googleUser.email} (${googleUser.displayName ?? "No Name"})',
      );

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final bool hasIdToken =
          googleAuth.idToken != null && googleAuth.idToken!.isNotEmpty;
      debugPrint('[GoogleSignIn] ID token retrieved: $hasIdToken');

      if (!hasIdToken) {
        throw Exception(
          'Google Sign-In failed to retrieve ID token from Google Identity Services.',
        );
      }

      debugPrint('[GoogleSignIn] Signing into Firebase with Google credential...');
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      debugPrint(
        '[GoogleSignIn] Firebase authentication successful: uid=${userCredential.user?.uid}, email=${userCredential.user?.email}',
      );

      return await _sendFirebaseUserToBackend(userCredential.user);
    } on GoogleSignInException catch (e) {
      debugPrint(
        '[GoogleSignIn] GoogleSignInException: code=${e.code}, description=${e.description}',
      );
      final codeStr = e.code.toString().toLowerCase();
      final descStr = (e.description ?? '').toLowerCase();

      if (codeStr.contains('canceled') ||
          codeStr.contains('cancelled') ||
          descStr.contains('canceled') ||
          descStr.contains('cancelled')) {
        if (descStr.contains('16') || descStr.contains('account auth failed')) {
          throw Exception(
            'Google Sign-In was cancelled or account auth failed. Ensure a Google account is added in Android Settings.',
          );
        }
        throw Exception('Google Sign-In was cancelled.');
      }

      if (descStr.contains('no account') ||
          descStr.contains('no google account')) {
        throw Exception('Add a Google account to the emulator.');
      }

      throw Exception('Google Sign-In failed: ${e.description ?? e.code}');
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[GoogleSignIn] FirebaseAuthException: code=${e.code}, message=${e.message}',
      );
      if (e.code == 'operation-not-allowed') {
        throw Exception(
          'Google sign-in is not enabled in Firebase project configuration.',
        );
      }
      throw Exception('Firebase authentication failed: ${e.message ?? e.code}');
    } catch (e) {
      debugPrint('[GoogleSignIn] Unexpected error during Google Sign-In: $e');
      rethrow;
    }
  }

  // ============================================================
  // GITHUB
  // ============================================================

  static Future<Map<String, dynamic>> signInWithGitHub() async {
    if (kIsWeb) {
      throw Exception(
        'Social login on Web is in preview. Please log in using your Email & Password.',
      );
    }

    try {
      debugPrint('[GitHubSignIn] Starting GitHub sign-in flow...');
      final provider = GithubAuthProvider();
      final userCredential = await _firebaseAuth.signInWithProvider(provider);
      debugPrint(
        '[GitHubSignIn] Firebase authentication successful: uid=${userCredential.user?.uid}',
      );
      return await _sendFirebaseUserToBackend(userCredential.user);
    } catch (e) {
      debugPrint('[GitHubSignIn] GitHub Sign-In failed: $e');
      rethrow;
    }
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

    debugPrint(
      '[SocialAuth] Retrieving Firebase ID token for user UID: ${user.uid}...',
    );
    final firebaseIdToken = await user.getIdToken();

    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw Exception('Failed to obtain Firebase ID token.');
    }

    debugPrint(
      '[SocialAuth] Exchanging Firebase ID token with FastAPI /api/v1/auth/social-login...',
    );
    final tokens = await ApiClient.socialLogin(firebaseIdToken);
    debugPrint(
      '[SocialAuth] FastAPI exchange succeeded. Received JWT tokens from backend.',
    );

    final accessToken = tokens['access_token']?.toString();
    final refreshToken = tokens['refresh_token']?.toString();

    if (accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty) {
      await TokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      debugPrint(
        '[SocialAuth] Access and refresh tokens successfully saved in TokenStorage.',
      );
    } else {
      throw Exception('Server did not return valid authentication tokens.');
    }

    return tokens;
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  static Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {
      // Firebase sign out error ignored.
    }

    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Google sign out error ignored.
      }
      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        // Disconnect can throw if not previously signed in with Google.
      }
    }
  }

  /// Instance method wrapper for `SocialAuthService().signOut()`.
  Future<void> logOut() => signOut();
}

