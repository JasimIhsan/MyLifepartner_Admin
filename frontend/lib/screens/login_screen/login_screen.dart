import 'package:flutter/material.dart';
import '../../core/responsive/adaptive_screen.dart';
import 'mobile/mobile_login_screen.dart';
import 'login_screen_stub.dart'
    if (dart.library.js_interop) 'web/web_login_screen_export.dart'
    if (dart.library.html) 'web/web_login_screen_export.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScreen(
      mobile: const MobileLoginScreen(),
      web: getPlatformWebLoginScreen(),
    );
  }
}

