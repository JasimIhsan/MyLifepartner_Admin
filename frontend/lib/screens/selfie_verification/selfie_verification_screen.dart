import 'package:flutter/material.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';
import 'mobile/mobile_selfie_verification_screen.dart';
import 'web/web_selfie_verification_screen.dart';

class SelfieVerificationScreen extends StatelessWidget {
  const SelfieVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: MobileSelfieVerificationScreen(),
      web: WebSelfieVerificationScreen(),
    );
  }
}
