import 'package:flutter/material.dart';
import 'package:life_partner_again/services/notification/firebase_notification_service.dart';
import 'package:life_partner_again/models/onboarding_status.dart';
import 'package:life_partner_again/services/auth_service.dart';
import 'package:life_partner_again/services/token_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isInitialized = false;
  bool _isLoggedIn = false;
  OnboardingStatus? _onboardingStatus;

  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _isLoggedIn;
  OnboardingStatus? get onboardingStatus => _onboardingStatus;

  Future<void> bootstrap() async {
    try {
      final accessToken = await TokenService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        _isLoggedIn = false;
        _onboardingStatus = null;
      } else {
        final status = await _authService.fetchMeOrThrow();
        _isLoggedIn = true;
        _onboardingStatus = status;
        await FirebaseNotificationService().setupAfterLogin();
      }
    } catch (e) {
      debugPrint("Auth bootstrap failed: $e");
      await TokenService.clearTokens();
      _isLoggedIn = false;
      _onboardingStatus = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void loginSuccess(OnboardingStatus status) {
    _isLoggedIn = true;
    _onboardingStatus = status;
    _isInitialized = true;
    notifyListeners();
    FirebaseNotificationService().setupAfterLogin();
  }

  void updateOnboardingStatus(OnboardingStatus status) {
    _onboardingStatus = status;
    notifyListeners();
  }

  /// Triggers GoRouter to re-evaluate its redirect logic.
  /// Used by SplashScreen after the brief animation delay.
  void triggerRedirect() {
    notifyListeners();
  }

  Future<void> logout() async {
    await FirebaseNotificationService().tearDownOnLogout();
    await _authService.logoutLocal();
    _isLoggedIn = false;
    _onboardingStatus = null;
    notifyListeners();
  }
}
