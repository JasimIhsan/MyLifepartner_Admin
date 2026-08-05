import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/services/notification/firebase_notification_service.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = context.read<AuthProvider>();

    // 1. Minimum 3-second splash duration
    final minimum3SecondDelay = Future.delayed(const Duration(seconds: 3));

    // 2. All required startup API/data fetching in parallel
    final startupDataInitialization = Future(() async {
      // Initialize Firebase notifications first as Auth bootstrap might depend on it.
      await FirebaseNotificationService().initialize();
      await authProvider.bootstrap();
    });

    // Wait for BOTH conditions to complete
    await Future.wait([minimum3SecondDelay, startupDataInitialization]);

    if (!mounted) return;

    // Signal that initialization is complete, triggering GoRouter to redirect
    authProvider.finishInitialization();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.white,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Logo and Title Center Block
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                      'assets/icons/app_logo.png',
                      height: 250,
                      width: 250,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),
              ],
            ),
            // footer information
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                        "Find Love, Begin Again",
                        style: GoogleFonts.outfit(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 300.ms)
                      .slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
