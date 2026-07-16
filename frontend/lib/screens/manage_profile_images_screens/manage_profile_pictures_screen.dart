import 'package:flutter/material.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';

import 'mobile/mobile_manage_profile_pictures_screen.dart';
import 'web/web_manage_profile_pictures_screen.dart';

class ManageProfilePicturesScreen extends StatelessWidget {
  const ManageProfilePicturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: MobileManageProfilePicturesScreen(),
      web: WebManageProfilePicturesScreen(),
    );
  }
}
