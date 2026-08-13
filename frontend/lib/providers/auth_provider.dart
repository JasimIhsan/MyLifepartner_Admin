import 'package:flutter/material.dart';
import 'package:life_partner_again/main.dart';
import 'package:life_partner_again/models/onboarding_status.dart';
import 'package:life_partner_again/providers/chat_provider.dart';
import 'package:life_partner_again/providers/subscription_provider.dart';
import 'package:life_partner_again/services/auth_service.dart';
import 'package:life_partner_again/services/chat_service.dart';
import 'package:life_partner_again/services/notification/firebase_notification_service.dart';
import 'package:life_partner_again/services/token_service.dart';
import 'package:life_partner_again/services/user_repository.dart';
import 'package:life_partner_again/services/zego_service.dart';
import 'package:life_partner_again/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isInitialized = false;
  bool _isLoggedIn = false;
  bool _isLoggingOut = false;
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
        notifyListeners();
      } else {
        final status = await _authService.fetchMeOrThrow();
        _isLoggedIn = true;
        _onboardingStatus = status;
        await FirebaseNotificationService().setupAfterLogin();
        await _setupZego(status);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Auth bootstrap failed: $e");
      await TokenService.clearTokens();
      _isLoggedIn = false;
      _onboardingStatus = null;
      notifyListeners();
    }
  }

  /// Called by SplashScreen when BOTH the minimum duration and bootstrap are complete.
  void finishInitialization() {
    _isInitialized = true;
    notifyListeners();
  }

  void loginSuccess(OnboardingStatus status) {
    _isLoggedIn = true;
    _onboardingStatus = status;
    _isInitialized = true;
    notifyListeners();
    FirebaseNotificationService().setupAfterLogin();
    _setupZego(status);
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
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      try {
        await FirebaseNotificationService().tearDownOnLogout();
      } catch (e) {
        debugPrint('FCM tearDownOnLogout failed: $e');
      }

      try {
        await ZegoService.instance.logout();
      } catch (e) {
        debugPrint('Zego logout failed: $e');
      }

      // Reset theme and clear subscription purchaser state.
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        context.read<ThemeProvider>().setThemeMode(ThemeMode.light);
        try {
          await context.read<SubscriptionProvider>().logout();
        } catch (e) {
          debugPrint('Subscription logout failed: $e');
        }
      }

      await _authService.logoutLocal();
      _isLoggedIn = false;
      _onboardingStatus = null;
      notifyListeners();
    } finally {
      _isLoggingOut = false;
    }
  }

  Future<void> _setupZego(OnboardingStatus status) async {
    try {
      String userName = 'User ${status.id}';
      try {
        final profile = await UserRepository().getUser();
        if (profile.name != null && profile.name!.trim().isNotEmpty) {
          userName = profile.name!;
        }
      } catch (_) {}

      final tokenData = await ChatApiService.getZegoToken();
      String? token = tokenData != null ? tokenData['token'] : null;

      await ZegoService.instance.login(
        status.id.toString(),
        userName,
        token: token,
      );
    } catch (e) {
      debugPrint('[AuthProvider] Zego setup failed: $e');
    }
  }

  /// Safety net for hot reloads or dropped sessions
  Future<void> ensureZegoLogin() async {
    if (_isLoggedIn &&
        _onboardingStatus != null &&
        !ZegoService.instance.isLoggedIn) {
      debugPrint('[AuthProvider] Safety net: Re-initializing Zego session...');
      await _setupZego(_onboardingStatus!);

      // Also re-trigger subscriptions in ChatProvider if needed
      if (ZegoService.instance.isLoggedIn) {
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          context.read<ChatProvider>().startListening();
        }
      }
    }
  }
}
