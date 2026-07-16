import 'package:flutter/material.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';

import 'mobile/mobile_profile_detail_screen.dart';
import 'web/web_profile_detail_screen.dart';

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: MobileProfileDetailScreen(),
      web: WebProfileDetailScreen(),
    );
  }
}
