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

  /// Fetches paginated in-app notifications from backend API (/notifications).
  Future<Map<String, dynamic>?> getNotifications({
    int page = 1,
    int limit = 20,
    String category = 'All',
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page, 'limit': limit};
      if (category != 'All') {
        queryParameters['category'] = category;
      }
      
      final response = await _client.get(
        '/notifications',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Error fetching notifications from backend API: $e');
    }
    return null;
  }

  /// Fetches only the unread notifications count (/notifications/unread-count).
  Future<int?> getUnreadCount() async {
    try {
      final response = await _client.get('/notifications/unread-count');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null && data['unreadCount'] != null) {
          final count = data['unreadCount'];
          return count is int
              ? count
              : int.tryParse(count.toString()) ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error fetching unread notification count: $e');
    }
    return null;
  }

  /// Marks all notifications for current user as read (/notifications/read-all).
  Future<bool> markAllAsRead() async {
    try {
      final response = await _client.patch('/notifications/read-all');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Marks a specific notification as read (/notifications/:id/read).
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _client.patch(
        '/notifications/$notificationId/read',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking notification $notificationId as read: $e');
      return false;
    }
  }
}

/// Backwards compatibility alias for NotificationApiService
typedef NotificationTokenService = NotificationApiService;
