import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/models/notification_types.dart';
import 'package:life_partner_again/main.dart' show navigatorKey;

class NotificationNavigationService {
  static final NotificationNavigationService _instance =
      NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  /// Handles routing based on notification payload.
  void handleNavigation(NotificationData data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (data.type) {
      case NotificationTypes.newMessage:
        if (data.conversationId != null) {
          // Go to chat detail screen
          context.push('/chat/${data.conversationId}');
        }
        break;

      case NotificationTypes.newLike:
      case NotificationTypes.newMatch:
        if (data.profileId != null) {
          // Go to profile detail screen
          context.push('/profile-detail/${data.profileId}');
        }
        break;

      case NotificationTypes.profileApproved:
      case NotificationTypes.profileRejected:
        // Go to home/profile which handles status
        context.go(AppRoutes.home);
        break;

      case NotificationTypes.subscriptionSuccess:
      case NotificationTypes.subscriptionExpiring:
      case NotificationTypes.paymentFailed:
        // Go to subscription management
        context.push(AppRoutes.subscription);
        break;

      default:
        // Do nothing or navigate to home
        debugPrint('Unknown notification type: ${data.type}');
        break;
    }
  }
}
