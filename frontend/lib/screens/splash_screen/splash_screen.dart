import 'package:flutter/material.dart';

import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/screens/home_screen/home_screen.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/screens/partner_preference/partner_preference_screen.dart';
import 'package:mylifepartner/screens/onboarding/onboarding_flow_screen.dart';
import 'package:mylifepartner/screens/profile_image_upload/profile_image_upload_screen.dart';
import 'package:mylifepartner/screens/selfie_verification/selfie_verification_screen.dart';
import 'package:mylifepartner/services/auth_service.dart';
import 'package:mylifepartner/services/token_service.dart';

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
      backgroundColor: AppColors.background,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Column(
                    children: [
                      Text(
                        'Life Partner Again',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find your perfect match',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withValues(alpha: 0.6),
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
