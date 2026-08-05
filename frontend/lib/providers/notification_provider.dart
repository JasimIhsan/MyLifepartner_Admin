import 'package:flutter/foundation.dart';
import 'package:life_partner_again/models/in_app_notification.dart';
import 'package:life_partner_again/models/notification_types.dart';
import 'package:life_partner_again/services/notification/firebase_notification_service.dart';
import 'package:life_partner_again/services/notification/notification_permission_service.dart';
import 'package:life_partner_again/services/notification_api_service.dart';

enum NotificationState { idle, initializing, ready, error }

class NotificationProvider extends ChangeNotifier {
  final FirebaseNotificationService _firebaseService =
      FirebaseNotificationService();
  final NotificationPermissionService _permissionService =
      NotificationPermissionService();
  final NotificationApiService _apiService = NotificationApiService();

  NotificationState _state = NotificationState.idle;
  bool _isPermissionGranted = false;
  NotificationData? _lastNotification;
  String? _error;

  List<InAppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoadingNotifications = false;

  NotificationState get state => _state;
  bool get isPermissionGranted => _isPermissionGranted;
  NotificationData? get lastNotification => _lastNotification;
  String? get error => _error;

  List<InAppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoadingNotifications => _isLoadingNotifications;

  /// Initializes notification engine and checks permission status.
  Future<void> initialize() async {
    _state = NotificationState.initializing;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.initialize();
      _isPermissionGranted = await _permissionService.isPermissionGranted();
      _state = NotificationState.ready;
    } catch (e) {
      _error = e.toString();
      _state = NotificationState.error;
      debugPrint('Error initializing NotificationProvider: $e');
    }
    notifyListeners();
  }

  /// Requests notification permissions from device OS.
  Future<bool> requestPermission() async {
    final granted = await _permissionService.requestPermission();
    _isPermissionGranted = granted;
    notifyListeners();
    return granted;
  }

  /// Called after successful user login to request permissions, sync token, & fetch notifications.
  Future<void> setupAfterLogin() async {
    try {
      await _firebaseService.setupAfterLogin();
      _isPermissionGranted = await _permissionService.isPermissionGranted();
      await fetchUnreadCount();
      await fetchNotifications();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error setting up notifications after login: $e');
    }
    notifyListeners();
  }

  /// Fetches unread notification count via separate endpoint.
  Future<void> fetchUnreadCount() async {
    final count = await _apiService.getUnreadCount();
    if (count != null) {
      _unreadCount = count;
      notifyListeners();
    }
  }

  /// Called on user logout to remove device FCM token from backend API.
  Future<void> tearDownOnLogout() async {
    try {
      await _firebaseService.tearDownOnLogout();
      _notifications.clear();
      _unreadCount = 0;
    } catch (e) {
      debugPrint('Error tearing down notifications on logout: $e');
    }
    notifyListeners();
  }

  /// Updates current received notification payload.
  void setLastNotification(NotificationData notification) {
    _lastNotification = notification;
    notifyListeners();
    // Refresh notifications list from server when push is received
    fetchNotifications();
  }

  /// Fetches in-app notifications from backend API.
  Future<void> fetchNotifications({int page = 1, int limit = 20}) async {
    _isLoadingNotifications = true;
    notifyListeners();

    final result = await _apiService.getNotifications(page: page, limit: limit);
    if (result != null) {
      final List rawItems = result['items'] ?? [];
      _notifications = rawItems
          .map(
            (item) => InAppNotification.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      _unreadCount = result['unreadCount'] is int
          ? result['unreadCount']
          : int.tryParse(result['unreadCount']?.toString() ?? '0') ?? 0;
    }

    _isLoadingNotifications = false;
    notifyListeners();
  }

  /// Automatically marks all unread notifications as read when opening notification screen.
  Future<void> markAllAsRead() async {
    if (_unreadCount == 0 && _notifications.every((n) => n.isRead)) return;

    // Optimistic UI update
    _unreadCount = 0;
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
        .toList();
    notifyListeners();

    final success = await _apiService.markAllAsRead();
    if (!success) {
      // Re-sync if API call fails
      fetchNotifications();
    }
  }

  /// Marks single notification as read.
  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || _notifications[index].isRead) return;

    // Optimistic UI update
    _notifications[index] = _notifications[index].copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();

    final success = await _apiService.markAsRead(notificationId);
    if (!success) {
      fetchNotifications();
    }
  }
}
