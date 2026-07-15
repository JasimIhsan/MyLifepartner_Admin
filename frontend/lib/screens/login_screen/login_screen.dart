import 'package:flutter/material.dart';
import '../../core/responsive/adaptive_screen.dart';
import 'mobile/mobile_login_screen.dart';
import 'web/web_login_screen.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: MobileLoginScreen(),
      web: WebLoginScreen(),
    );
  }
}
