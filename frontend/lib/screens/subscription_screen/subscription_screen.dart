import 'package:flutter/material.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';

import 'mobile/mobile_subscription_screen.dart';
import 'web/web_subscription_screen.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: MobileSubscriptionScreen(),
      web: WebSubscriptionScreen(),
    );
  }
}
