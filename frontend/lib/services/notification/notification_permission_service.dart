import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionService {
  static final NotificationPermissionService _instance = NotificationPermissionService._internal();
  factory NotificationPermissionService() => _instance;
  NotificationPermissionService._internal();

  /// Requests notification permission on iOS and Android 13+.
  Future<bool> requestPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Checks if notification permission is currently granted.
  Future<bool> isPermissionGranted() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        return await Permission.notification.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }
}
