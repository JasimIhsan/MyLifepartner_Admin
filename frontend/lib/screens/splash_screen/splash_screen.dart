import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
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
    _proceed();
  }

  // Auth is already bootstrapped in main(). We just show the splash animation
  // briefly and then trigger GoRouter to re-evaluate and navigate to the
  // correct screen based on the already-known auth state.
  Future<void> _proceed() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    context.read<AuthProvider>().triggerRedirect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.primaryDark,
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Logo and Title Center Block
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Image.asset(
                        'assets/icons/app_logo.png',
                        height: 96,
                        width: 96,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 64,
                            ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 24),
                Text(
                      "Life Partner Again",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 300.ms)
                    .slideY(begin: 0.1, end: 0),
              ],
            ),
            // Loading and footer information
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ).animate().fadeIn(duration: 800.ms, delay: 500.ms),
                  const SizedBox(height: 24),
                  Text(
                    "Trusted Platform",
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(duration: 800.ms, delay: 700.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
