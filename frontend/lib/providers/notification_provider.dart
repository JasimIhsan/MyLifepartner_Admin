import 'package:flutter/foundation.dart';
import 'package:life_partner_again/models/in_app_notification.dart';
import 'package:life_partner_again/models/notification_types.dart';
import 'package:life_partner_again/services/notification/firebase_notification_service.dart';
import 'package:life_partner_again/services/notification/notification_permission_service.dart';
import 'package:life_partner_again/services/notification_api_service.dart';

enum NotificationState { idle, initializing, ready, error }

class CategoryPaginationState {
  List<InAppNotification> notifications = [];
  int page = 1;
  bool hasMore = true;
  bool isLoading = false;
  int totalCount = 0;
}

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

  int _unreadCount = 0;
  String _selectedCategory = 'All';

  final Map<String, CategoryPaginationState> _categoryStates = {
    'All': CategoryPaginationState(),
    'Messages': CategoryPaginationState(),
    'Subscriptions': CategoryPaginationState(),
    'Alerts': CategoryPaginationState(),
    'System': CategoryPaginationState(),
  };

  NotificationState get state => _state;
  bool get isPermissionGranted => _isPermissionGranted;
  NotificationData? get lastNotification => _lastNotification;
  String? get error => _error;

  String get selectedCategory => _selectedCategory;
  List<InAppNotification> get notifications =>
      _categoryStates[_selectedCategory]!.notifications;
  int get totalCount => _categoryStates[_selectedCategory]!.totalCount;
  bool get isLoadingNotifications =>
      _categoryStates[_selectedCategory]!.isLoading;
  bool get hasMore => _categoryStates[_selectedCategory]!.hasMore;
  int get unreadCount => _unreadCount;

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
      await fetchNotifications(isRefresh: true);
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
      for (final state in _categoryStates.values) {
        state.notifications.clear();
        state.page = 1;
        state.hasMore = true;
        state.totalCount = 0;
      }
      _unreadCount = 0;
      _selectedCategory = 'All';
    } catch (e) {
      debugPrint('Error tearing down notifications on logout: $e');
    }
    notifyListeners();
  }

  /// Updates current received notification payload.
  void setLastNotification(NotificationData notification) {
    _lastNotification = notification;
    notifyListeners();
    // Refresh notifications list from server when push is received for current category
    fetchNotifications(isRefresh: true);
  }

  /// Changes selected category and fetches if empty
  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();

    if (_categoryStates[category]!.notifications.isEmpty) {
      fetchNotifications(isRefresh: true);
    }
  }

  /// Fetches in-app notifications from backend API.
  Future<void> fetchNotifications({bool isRefresh = false, int limit = 20}) async {
    final currentState = _categoryStates[_selectedCategory]!;
    
    if (currentState.isLoading) return;
    if (!isRefresh && !currentState.hasMore) return;

    currentState.isLoading = true;
    if (isRefresh) {
      currentState.page = 1;
    }
    notifyListeners();

    final result = await _apiService.getNotifications(
      page: currentState.page,
      limit: limit,
      category: _selectedCategory,
    );

    if (result != null) {
      final List rawItems = result['items'] ?? [];
      final fetchedNotifications = rawItems
          .map(
            (item) => InAppNotification.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      if (isRefresh) {
        currentState.notifications = fetchedNotifications;
      } else {
        currentState.notifications.addAll(fetchedNotifications);
      }

      currentState.totalCount = result['total'] is int
          ? result['total']
          : int.tryParse(result['total']?.toString() ?? '0') ?? 0;
          
      final totalPages = result['totalPages'] is int
          ? result['totalPages']
          : int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;

      currentState.hasMore = currentState.page < totalPages;
      if (currentState.hasMore) {
        currentState.page++;
      }

      _unreadCount = result['unreadCount'] is int
          ? result['unreadCount']
          : int.tryParse(result['unreadCount']?.toString() ?? '0') ?? 0;
    }

    currentState.isLoading = false;
    notifyListeners();
  }

  /// Automatically marks all unread notifications as read when opening notification screen.
  Future<void> markAllAsRead() async {
    if (_unreadCount == 0 && notifications.every((n) => n.isRead)) return;

    // Optimistic UI update across all categories
    _unreadCount = 0;
    for (final state in _categoryStates.values) {
      state.notifications = state.notifications
          .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
          .toList();
    }
    notifyListeners();

    final success = await _apiService.markAllAsRead();
    if (!success) {
      // Re-sync if API call fails
      fetchNotifications(isRefresh: true);
    }
  }

  /// Marks single notification as read.
  Future<void> markAsRead(int notificationId) async {
    bool foundAndUnread = false;

    // Optimistic UI update across all categories
    for (final state in _categoryStates.values) {
      final index = state.notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !state.notifications[index].isRead) {
        state.notifications[index] = state.notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        foundAndUnread = true;
      }
    }

    if (!foundAndUnread) return;

    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();

    final success = await _apiService.markAsRead(notificationId);
    if (!success) {
      fetchNotifications(isRefresh: true);
    }
  }
}
