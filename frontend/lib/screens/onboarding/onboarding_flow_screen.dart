import 'package:flutter/material.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';
import 'mobile/mobile_onboarding_screen.dart';
import 'web/web_onboarding_screen.dart';

class OnboardingFlowScreen extends StatelessWidget {
  const OnboardingFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: MobileOnboardingScreen(),
      web: WebOnboardingScreen(),
    );
  }
}
