import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/home_screen/home_screen.dart';
import 'package:life_partner_again/screens/login_screen/login_screen.dart';
import 'package:life_partner_again/screens/partner_preference/partner_preference_screen.dart';
import 'package:life_partner_again/screens/onboarding/onboarding_flow_screen.dart';
import 'package:life_partner_again/screens/profile_image_upload/profile_image_upload_screen.dart';
import 'package:life_partner_again/screens/selfie_verification/selfie_verification_screen.dart';
import 'package:life_partner_again/services/auth_service.dart';
import 'package:life_partner_again/services/token_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(seconds: 1));

    final accessToken = await TokenService.getAccessToken();
    if (!mounted) return;

    if (accessToken == null || accessToken.isEmpty) {
      _goTo(const LoginPage());
      return;
    }

    try {
      final me = await _authService.fetchMeOrThrow();
      if (!mounted) return;

      if (!me.hasCompletedBasicDetails) {
        _goTo(const OnboardingFlowScreen());
      } else if (!me.hasCompletedPartnerPreference) {
        _goTo(const PartnerPreferenceScreen());
      } else if (!me.hasCompletedImageUpload) {
        _goTo(const ProfileImageUploadScreen());
      } else if (me.selfieStatus == null || me.selfieStatus == "NONE") {
        _goTo(const SelfieVerificationScreen());
      } else {
        _goTo(const HomePage());
      }
    } catch (_) {
      // If access token is expired, ApiService interceptor will try refresh-token + retry.
      // If refresh fails, tokens are cleared; we fall back to login.
      await TokenService.clearTokens();
      if (!mounted) return;
      _goTo(const LoginPage());
    }
  }

  void _goTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SvgPicture.asset(
              'assets/images/splash.svg',
              fit: BoxFit.cover,
            ),
            const Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
