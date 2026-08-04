import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:life_partner_again/services/api_service.dart';

class NotificationTokenService {
  static final NotificationTokenService _instance =
      NotificationTokenService._internal();
  factory NotificationTokenService() => _instance;
  NotificationTokenService._internal();

  static final _client = ApiService.client;

  /// Retrieves the FCM token and sends it to the backend.
  /// Should be called after successful login.
  Future<void> registerToken() async {
    try {
      // For iOS, ensure APNs token is available before getting FCM token
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('APNs token not yet available, waiting...');
          // Optional: implement a retry mechanism or wait
          // For now we continue, as Firebase handles some of this internally,
          // but logging helps debugging.
        }
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _sendTokenToBackend(fcmToken);
      }

      // Listen for token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken);
      });
    } catch (e) {
      debugPrint('Error registering notification token: $e');
    }
  }

  /// Removes the current FCM token from the backend.
  /// Should be called during logout.
  Future<void> removeToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _client.delete('/device-tokens', data: {'token': fcmToken});
        debugPrint('Notification token removed from backend');
      }

      // Optionally delete instance ID so a new one is generated next time
      // await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Error removing notification token: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'IOS'
          : 'ANDROID';

      await _client.post(
        '/device-tokens',
        data: {'token': token, 'platform': platform},
      );
      debugPrint('Notification token registered with backend');
    } catch (e) {
      debugPrint('Error sending token to backend: $e');
    }
  }
}
