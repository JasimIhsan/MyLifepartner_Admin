import 'package:flutter/foundation.dart';
import 'package:life_partner_again/models/notification_types.dart';
import 'package:life_partner_again/services/notification/firebase_notification_service.dart';
import 'package:life_partner_again/services/notification/notification_permission_service.dart';

enum NotificationState { idle, initializing, ready, error }

class NotificationProvider extends ChangeNotifier {
  final FirebaseNotificationService _firebaseService = FirebaseNotificationService();
  final NotificationPermissionService _permissionService = NotificationPermissionService();

  NotificationState _state = NotificationState.idle;
  bool _isPermissionGranted = false;
  NotificationData? _lastNotification;
  String? _error;

  NotificationState get state => _state;
  bool get isPermissionGranted => _isPermissionGranted;
  NotificationData? get lastNotification => _lastNotification;
  String? get error => _error;

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

  /// Called after successful user login to request permissions & sync token to backend API.
  Future<void> setupAfterLogin() async {
    try {
      await _firebaseService.setupAfterLogin();
      _isPermissionGranted = await _permissionService.isPermissionGranted();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error setting up notifications after login: $e');
    }
    notifyListeners();
  }

  /// Called on user logout to remove device FCM token from backend API.
  Future<void> tearDownOnLogout() async {
    try {
      await _firebaseService.tearDownOnLogout();
    } catch (e) {
      debugPrint('Error tearing down notifications on logout: $e');
    }
    notifyListeners();
  }

  /// Updates current received notification payload.
  void setLastNotification(NotificationData notification) {
    _lastNotification = notification;
    notifyListeners();
  }
}
