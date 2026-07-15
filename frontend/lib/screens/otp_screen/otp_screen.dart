import 'package:flutter/material.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';
import 'mobile/mobile_otp_screen.dart';
import 'web/web_otp_screen.dart';

class OtpPage extends StatelessWidget {
  final String email;
  final bool isExistingUser;
  final bool isPasswordReset;

  const OtpPage({
    super.key,
    required this.email,
    required this.isExistingUser,
    this.isPasswordReset = false,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveScreen(
      mobile: MobileOtpScreen(
        email: email,
        isExistingUser: isExistingUser,
        isPasswordReset: isPasswordReset,
      ),
      web: WebOtpScreen(
        email: email,
        isExistingUser: isExistingUser,
        isPasswordReset: isPasswordReset,
      ),
    );
  }
}
