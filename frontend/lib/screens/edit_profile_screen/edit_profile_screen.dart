import 'package:flutter/material.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';
import 'package:life_partner_again/models/auth_response.dart';

import 'mobile/mobile_edit_profile_screen.dart';
import 'web/web_edit_profile_screen.dart';

class EditProfileScreen extends StatelessWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScreen(
      mobile: MobileEditProfileScreen(user: user),
      web: WebEditProfileScreen(user: user),
    );
  }
}
