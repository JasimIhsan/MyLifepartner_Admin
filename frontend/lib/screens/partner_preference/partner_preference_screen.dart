import 'package:flutter/material.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';
import 'mobile/mobile_partner_preference_screen.dart';
import 'web/web_partner_preference_screen.dart';

class PartnerPreferenceScreen extends StatelessWidget {
  const PartnerPreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: MobilePartnerPreferenceScreen(),
      web: WebPartnerPreferenceScreen(),
    );
  }
}
