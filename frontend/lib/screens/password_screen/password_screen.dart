import 'package:flutter/material.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';
import 'mobile/mobile_password_screen.dart';
import 'web/web_password_screen.dart';

class PasswordScreen extends StatelessWidget {
  final String email;
  final bool isExistingUser;
  final bool isPasswordReset;

  const PasswordScreen({
    super.key,
    required this.email,
    required this.isExistingUser,
    this.isPasswordReset = false,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveScreen(
      mobile: MobilePasswordScreen(
        email: email,
        isExistingUser: isExistingUser,
        isPasswordReset: isPasswordReset,
      ),
      web: WebPasswordScreen(
        email: email,
        isExistingUser: isExistingUser,
        isPasswordReset: isPasswordReset,
      ),
    );
  }
}
