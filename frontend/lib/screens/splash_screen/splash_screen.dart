import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
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
      _goTo(AppRoutes.landing);
      return;
    }

    try {
      final me = await _authService.fetchMeOrThrow();
      if (!mounted) return;

      if (!me.hasCompletedBasicDetails) {
        _goTo(AppRoutes.onboarding);
      } else if (!me.hasCompletedPartnerPreference) {
        _goTo(AppRoutes.partnerPreference);
      } else if (!me.hasCompletedImageUpload) {
        _goTo(AppRoutes.profileImageUpload);
      } else if (me.selfieStatus == null || me.selfieStatus == "NONE") {
        _goTo(AppRoutes.selfieVerification);
      } else {
        _goTo(AppRoutes.home);
      }
    } catch (_) {
      // If access token is expired, ApiService interceptor will try refresh-token + retry.
      // If refresh fails, tokens are cleared; we fall back to landing.
      await TokenService.clearTokens();
      if (!mounted) return;
      _goTo(AppRoutes.landing);
    }
  }

  void _goTo(String routeName) {
    Navigator.pushReplacementNamed(
      context,
      routeName,
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
