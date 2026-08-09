import 'package:flutter/material.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';

import 'mobile/mobile_edit_partner_preference_screen.dart';
import 'web/web_edit_partner_preference_screen.dart';

class EditPartnerPreferenceScreen extends StatelessWidget {
  const EditPartnerPreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: MobileEditPartnerPreferenceScreen(),
      web: WebEditPartnerPreferenceScreen(),
    );
  }
}
