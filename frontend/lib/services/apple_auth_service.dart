import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as dart_math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:life_partner_again/config/env.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthException implements Exception {
  final String message;
  final dynamic originalError;

  AppleAuthException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

class AppleAuthCancelledException implements Exception {
  final String message;
  AppleAuthCancelledException([this.message = "Apple Sign-In was cancelled"]);

  @override
  String toString() => message;
}

class AppleAuthResult {
  final String identityToken;
  final String authorizationCode;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String platform;
  final String? rawNonce;

  AppleAuthResult({
    required this.identityToken,
    required this.authorizationCode,
    this.email,
    this.firstName,
    this.lastName,
    required this.platform,
    this.rawNonce,
  });
}

class AppleAuthService {
  static final AppleAuthService instance = AppleAuthService._internal();

  AppleAuthService._internal();

  bool _isSigningIn = false;
  bool get isSigningIn => _isSigningIn;

  // Generates a random nonce
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = dart_math.Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // SHA256 hashes the nonce as required by Apple
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<AppleAuthResult?> authenticate() async {
    if (_isSigningIn) {
      debugPrint("AppleAuthService: Sign in already in progress.");
      return null;
    }

    _isSigningIn = true;
    final String rawNonce = _generateNonce();
    final String hashedNonce = _sha256ofString(rawNonce);
    String detectedPlatform = 'unknown';

    try {
      if (kIsWeb) {
        detectedPlatform = 'web';
      } else if (Platform.isIOS) {
        detectedPlatform = 'ios';
      } else if (Platform.isAndroid) {
        detectedPlatform = 'android';
      } else {
        // Apple Sign In is not supported on desktop platforms (macOS, Windows, Linux).
        throw AppleAuthException(
          'Apple Sign In is not supported on this platform.',
        );
      }

      debugPrint(
        "AppleAuthService: Starting Apple Sign-In on platform: $detectedPlatform",
      );

      AuthorizationCredentialAppleID credential;

      if (!kIsWeb && Platform.isIOS) {
        // Native iOS: uses the system AuthenticationServices framework.
        credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );
      } else {
        // Web and Android: opens Apple login in a browser popup.
        // For Android: redirectUri points to our backend callback which responds with a deep link (lifepartneragain://)
        // For Web: redirectUri points to the production Vercel domain.
        // Note: The Web origin (https://life-partner-again.vercel.app/) MUST be registered as a Return URL in the Apple Developer Console.
        final Uri redirectUri = kIsWeb
            ? Uri.parse('https://life-partner-again.vercel.app/')
            : Uri.parse(Env.appleRedirectUri);

        credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: 'com.premiumglobalcorp.lifepartneragain.web',
            redirectUri: redirectUri,
          ),
        );
      }

      debugPrint("AppleAuthService: Credential received.");

      final identityToken = credential.identityToken;
      final authorizationCode = credential.authorizationCode;

      debugPrint(
        "AppleAuthService: identityToken present: ${identityToken != null && identityToken.isNotEmpty}",
      );
      debugPrint(
        "AppleAuthService: authorizationCode present: ${authorizationCode.isNotEmpty}",
      );

      if (identityToken == null || identityToken.isEmpty) {
        throw AppleAuthException("Identity token is missing or empty.");
      }

      if (authorizationCode.isEmpty) {
        throw AppleAuthException("Authorization code is missing or empty.");
      }

      debugPrint("AppleAuthService: Login completed successfully.");

      return AppleAuthResult(
        identityToken: identityToken,
        authorizationCode: authorizationCode,
        email: credential.email,
        firstName: credential.givenName,
        lastName: credential.familyName,
        platform: detectedPlatform,
        rawNonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint(
        "AppleAuthService Exception: code=${e.code}, message=${e.message}",
      );
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AppleAuthCancelledException("Sign in cancelled by user.");
      }
      throw AppleAuthException("Apple Sign-In failed: ${e.message}", e);
    } catch (e) {
      debugPrint("AppleAuthService Unknown Exception: $e");
      final String errorStr = e.toString().toLowerCase();

      if (errorStr.contains("cancel") || errorStr.contains("closed")) {
        throw AppleAuthCancelledException("Sign in cancelled by user.");
      }

      // UNKNOWN_SIWA_ERROR = Apple's JS SDK rejected the request pre-flight.
      // This is ALWAYS an Apple Developer Console configuration problem, not a code bug.
      // Fix checklist:
      //   1. Go to developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → Services IDs
      //   2. Select: com.premiumglobalcorp.lifepartneragain.web → Edit (Sign In with Apple)
      //   3. Domains and Subdomains: add life-partner-again.vercel.app (localhost not supported)
      //   4. Return URLs: must include https://life-partner-again.vercel.app/ and ${Env.appleRedirectUri}
      if (errorStr.contains("unknown_siwa_error") ||
          errorStr.contains("siwa_error")) {
        debugPrint(
          "AppleAuthService: UNKNOWN_SIWA_ERROR detected.\n"
          "This is an Apple Developer Console configuration issue:\n"
          "  • Service ID: com.premiumglobalcorp.lifepartneragain.web\n"
          "  • Expected Web redirect URI: https://life-partner-again.vercel.app/\n"
          "  • Expected Android redirect URI: ${Env.appleRedirectUri}\n"
          "  • The domain 'life-partner-again.vercel.app' MUST be registered under Domains and Subdomains.\n"
          "  • localhost is NOT supported by Apple — use the production domain.",
        );
        throw AppleAuthException(
          "Apple Sign In is not configured for this domain. "
          "Please contact support or try signing in on the mobile app.",
          e,
        );
      }

      throw AppleAuthException(
        "Failed to sign in with Apple. Please try again.",
        e,
      );
    } finally {
      _isSigningIn = false;
    }
  }
}
