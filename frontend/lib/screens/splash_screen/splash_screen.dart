import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/screens/home_screen/home_screen.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/screens/partner_preference/partner_preference_screen.dart';
import 'package:mylifepartner/screens/profile_completion/profile_completion_screen.dart';
import 'package:mylifepartner/screens/profile_image_upload/profile_image_upload_screen.dart';
import 'package:mylifepartner/screens/questionaire_screen/questionaire_screen.dart';
import 'package:mylifepartner/screens/selfie_verification/selfie_verification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () async {
      final sharedPrefs = await SharedPreferences.getInstance();
      final isLoggedIn = sharedPrefs.getBool("isLoggedIn") ?? false;
      final profileStatus =
          sharedPrefs.getString("profileStatus") ?? "INCOMPLETE";
      final hasCompletedImageUpload =
          sharedPrefs.getBool("hasCompletedImageUpload") ?? false;
      final hasCompletedPartnerPreference =
          sharedPrefs.getBool("hasCompletedPartnerPreference") ?? false;
      final hasCompletedBasicDetails =
          sharedPrefs.getBool("hasCompletedBasicDetails") ?? false;
      final selfieStatus = sharedPrefs.getString("selfieStatus");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              if (isLoggedIn) {
                if (!hasCompletedBasicDetails) {
                  return const ProfileCompletionScreen();
                } else if (!hasCompletedPartnerPreference) {
                  return const PartnerPreferenceScreen();
                } else if (profileStatus == "INCOMPLETE") {
                  return const QuestionaireScreen();
                } else {
                  if (hasCompletedImageUpload) {
                    if (selfieStatus != null && selfieStatus != "NONE") {
                      return const HomePage();
                    } else {
                      return const SelfieVerificationScreen();
                    }
                  } else {
                    return const ProfileImageUploadScreen();
                  }
                }
              }
              return const LoginPage();
            },
          ),
        );
      }
    });
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
                  Container(
                    // padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        "assets/icons/app_logo.png",
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Column(
                    children: [
                      Text(
                        'Life Partner Again',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find your perfect match',
                        style: GoogleFonts.poppins(
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
