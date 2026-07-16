import 'package:flutter/material.dart';
import '../../core/responsive/adaptive_screen.dart';
import 'mobile/mobile_profile_screen.dart';
import 'web/web_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: MobileProfileScreen(),
      web: WebProfileScreen(),
    );
  }
}
