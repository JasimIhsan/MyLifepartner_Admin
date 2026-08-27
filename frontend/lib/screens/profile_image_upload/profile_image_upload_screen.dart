import 'package:flutter/material.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';
import 'mobile/mobile_profile_image_upload_screen.dart';
import 'web/web_profile_image_upload_screen.dart';

class ProfileImageUploadScreen extends StatelessWidget {
  const ProfileImageUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: MobileProfileImageUploadScreen(),
      web: WebProfileImageUploadScreen(),
    );
  }
}
