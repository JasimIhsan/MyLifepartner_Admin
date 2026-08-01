import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:life_partner_again/config/env.dart';

class GoogleAuthException implements Exception {
  final String message;
  final dynamic originalError;

  GoogleAuthException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

class GoogleAuthCancelledException implements Exception {
  final String message;
  GoogleAuthCancelledException([this.message = "Google Sign-In was cancelled"]);

  @override
  String toString() => message;
}

class GoogleAuthService {
  static final GoogleAuthService instance = GoogleAuthService._internal();

  GoogleAuthService._internal();

  bool _isInitialized = false;
  bool _isSigningIn = false;

  bool get isSigningIn => _isSigningIn;

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        final bool hasWebClientId = Env.googleWebClientId.isNotEmpty;
        debugPrint(
          "GoogleAuthService: Platform=Web, WebClientID Configured=$hasWebClientId",
        );

        await GoogleSignIn.instance.initialize(clientId: Env.googleWebClientId);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final bool hasIosClientId = Env.googleIosClientId.isNotEmpty;
        final bool hasServerClientId = Env.googleWebClientId.isNotEmpty;
        debugPrint(
          "GoogleAuthService: Platform=iOS, iOSClientID Configured=$hasIosClientId, ServerClientID Configured=$hasServerClientId",
        );

        await GoogleSignIn.instance.initialize(
          clientId: Env.googleIosClientId,
          serverClientId: Env.googleWebClientId,
        );
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final bool hasServerClientId = Env.googleServerClientId.isNotEmpty;
        debugPrint(
          "GoogleAuthService: Platform=Android, ServerClientID Configured=$hasServerClientId, ServerClientID=${Env.googleServerClientId}",
        );

        await GoogleSignIn.instance.initialize(
          serverClientId: Env.googleServerClientId,
        );
      } else {
        debugPrint("GoogleAuthService: Platform=${defaultTargetPlatform.name}");
        await GoogleSignIn.instance.initialize(
          serverClientId: Env.googleWebClientId,
        );
      }

      _isInitialized = true;
      debugPrint("GoogleAuthService: Initialization success.");
    } on PlatformException catch (e, stackTrace) {
      // Credential Manager errors on Android surface as PlatformException.
      // Log the code so it appears in release crash logs / Play Console ANRs.
      debugPrint(
        "GoogleAuthService: Initialization PlatformException: code=${e.code}, message=${e.message}, details=${e.details}\n$stackTrace",
      );
      _isInitialized = false; // allow retry on next sign-in attempt
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("GoogleAuthService: Initialization failed: $e\n$stackTrace");
      _isInitialized = false; // allow retry on next sign-in attempt
      rethrow;
    }
  }

  Future<String?> authenticate() async {
    if (_isSigningIn) {
      debugPrint("GoogleAuthService: Sign in already in progress.");
      return null;
    }

    _isSigningIn = true;

    try {
      await ensureInitialized();

      if (kIsWeb) {
        throw GoogleAuthException(
          "Direct authenticate() call is not supported on Flutter Web. Use the Web Google Sign-In button or flow instead.",
        );
      }

      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate();

      final GoogleSignInAuthentication authentication = account.authentication;
      final String? idToken = authentication.idToken;
      final bool hasIdToken = idToken != null && idToken.isNotEmpty;

      debugPrint(
        "GoogleAuthService: Authenticated successfully. Received idToken=$hasIdToken",
      );

      if (!hasIdToken) {
        throw GoogleAuthException("Could not retrieve ID token from Google.");
      }

      return idToken;
    } on PlatformException catch (e) {
      debugPrint(
        "GoogleAuthService Platform Exception: code=${e.code}, message=${e.message}",
      );
      if (e.code == 'canceled' || e.code == 'popup_closed_by_user') {
        throw GoogleAuthCancelledException("Sign in cancelled by user.");
      }
      throw GoogleAuthException(
        "Google Sign-In failed: ${e.message ?? e.code}",
        e,
      );
    } catch (e) {
      debugPrint("GoogleAuthService Exception: $e");
      final String errorStr = e.toString().toLowerCase();
      if (errorStr.contains("cancel") || errorStr.contains("popup_closed")) {
        throw GoogleAuthCancelledException("Sign in cancelled by user.");
      }
      if (e is GoogleAuthCancelledException || e is GoogleAuthException) {
        rethrow;
      }
      throw GoogleAuthException(
        "Failed to sign in with Google. Please try again.",
        e,
      );
    } finally {
      _isSigningIn = false;
    }
  }
}
