import 'package:flutter/material.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';
import 'package:life_partner_again/screens/notification_screen/mobile/mobile_notification_screen.dart';
import 'package:life_partner_again/screens/notification_screen/web/web_notification_dropdown.dart';

class NotificationScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const NotificationScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScreen(
      mobile: MobileNotificationScreen(onBack: onBack ?? () {}),
      web: const WebNotificationDropdown(),
    );
  }
}
