import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:life_partner_again/models/notification_types.dart';
import 'package:life_partner_again/services/notification/local_notification_service.dart';
import 'package:life_partner_again/services/notification/notification_navigation_service.dart';
import 'package:life_partner_again/services/notification/notification_permission_service.dart';
import 'package:life_partner_again/services/notification_api_service.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  debugPrint("Handling a background message: ${message.messageId}");
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final LocalNotificationService _localNotificationService =
      LocalNotificationService();
  final NotificationNavigationService _navigationService =
      NotificationNavigationService();
  final NotificationPermissionService _permissionService =
      NotificationPermissionService();
  final NotificationApiService _apiService = NotificationApiService();

  Future<void> initialize() async {
    debugPrint(
      '  👉 [FCM] Step 4a: Initializing Local Notification Service...',
    );
    try {
      await _localNotificationService.initialize();
      debugPrint('  ✅ [FCM] Step 4a: Local Notifications initialized.');
    } catch (e) {
      debugPrint('  ❌ [FCM] Step 4a: Local Notifications failed: $e');
    }

    debugPrint(
      '  👉 [FCM] Step 4b: Registering background handler & listeners...',
    );
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      debugPrint('  ✅ [FCM] Step 4b: FCM Listeners registered.');
    } catch (e) {
      debugPrint('  ❌ [FCM] Step 4b: Registering FCM Listeners failed: $e');
    }

    debugPrint(
      '  👉 [FCM] Step 4c: Fetching getInitialMessage (can hang on iOS Simulator)...',
    );
    try {
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint(
                '  ⚠️ [FCM] Step 4c: getInitialMessage timed out (expected on iOS Simulator). Skipping.',
              );
              return null;
            },
          );
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
      debugPrint('  ✅ [FCM] Step 4c: Initial message check finished.');
    } catch (e) {
      debugPrint('  ❌ [FCM] Step 4c: Error getting initial FCM message: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint(
        'Message also contained a notification: ${message.notification}',
      );
      _localNotificationService.showNotification(
        id: message.hashCode,
        title: message.notification?.title,
        body: message.notification?.body,
        data: message.data,
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('A new onMessageOpenedApp event was published!');
    final notificationData = NotificationData.fromMap(message.data);
    _navigationService.handleNavigation(notificationData);
  }

  /// Request permissions and register token.
  /// Typically called after login.
  Future<void> setupAfterLogin() async {
    final granted = await _permissionService.requestPermission();
    if (granted) {
      await _apiService.registerToken();
    }
  }

  /// Remove token. Typically called on logout.
  Future<void> tearDownOnLogout() async {
    await _apiService.removeToken();
  }
}
