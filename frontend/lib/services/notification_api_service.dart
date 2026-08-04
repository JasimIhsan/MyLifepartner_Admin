import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:life_partner_again/services/api_service.dart';

class NotificationApiService {
  static final NotificationApiService _instance =
      NotificationApiService._internal();
  factory NotificationApiService() => _instance;
  NotificationApiService._internal();

  static final _client = ApiService.client;

  /// Retrieves the FCM token and sends it to the backend endpoint (/device-tokens).
  /// Called after successful login or token refresh.
  Future<void> registerToken() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('APNs token not yet available, waiting...');
        }
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await sendTokenToBackend(fcmToken);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        sendTokenToBackend(newToken);
      });
    } catch (e) {
      debugPrint('Error registering notification token: $e');
    }
  }

  /// Removes the current FCM token from the backend.
  /// Called during logout.
  Future<void> removeToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _client.delete('/device-tokens', data: {'token': fcmToken});
        debugPrint('Notification token removed from backend');
      }
    } catch (e) {
      debugPrint('Error removing notification token: $e');
    }
  }

  /// Posts FCM token and platform to /device-tokens API endpoint.
  Future<void> sendTokenToBackend(String token) async {
    try {
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'IOS'
          : 'ANDROID';

      await _client.post(
        '/device-tokens',
        data: {'token': token, 'platform': platform},
      );
      debugPrint('Notification token registered with backend API');
    } catch (e) {
      debugPrint('Error sending token to backend API: $e');
    }
  }
}

/// Backwards compatibility alias for NotificationApiService
typedef NotificationTokenService = NotificationApiService;
