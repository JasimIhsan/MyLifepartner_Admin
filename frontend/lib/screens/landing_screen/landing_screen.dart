import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/providers/image_asset_provider.dart';
import 'package:mylifepartner/shared/widgets/custom_button.dart';
import 'package:provider/provider.dart';

import '../splash_screen/splash_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImageAssetProvider>().loadAssets('ONBOARDING_SCREEN');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Consumer<ImageAssetProvider>(
          builder: (context, provider, child) {
            final state = provider.getState('ONBOARDING_SCREEN');
            final landingAsset = provider.getFeaturedAsset('ONBOARDING_SCREEN');

            return Stack(
              children: [
                // ─── Background Image or Loader ──────────────────────────────────
                Positioned.fill(
                  child: state == ImageAssetLoadState.loading
                      ? Container(
                          color: Colors.white,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : (landingAsset != null
                            ? Image.network(
                                landingAsset.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultBackground(),
                              )
                            : _buildDefaultBackground()),
                ),

                // ─── Gradient Overlay ──────────────────────────────────────────
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),

                // ─── Main Content ─────────────────────────────────────────────
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        // Logo Placeholder
                        _buildLogo(),
                        const Spacer(),
                        // Features Row
                        _buildFeaturesRow(),
                        const SizedBox(height: 40),
                        // Headline & Subheadline
                        _buildTextSection(),
                        const SizedBox(height: 32),
                        // CTA Button
                        _buildCtaButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultBackground() {
    return Image.asset(
      'assets/images/landing_couple.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white54,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child:
          Image.asset(
                'assets/icons/app_logo.png',
                height: 200,
                width: 200,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 100,
                ),
              )
              .animate()
              .fadeIn(duration: 800.ms)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
    );
  }

  Widget _buildFeaturesRow() {
    return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFeatureItem(
              Icons.verified_user_outlined,
              'Verified Profiles',
            ),
            _buildFeatureItem(Icons.favorite_outline_rounded, 'Real Love'),
            _buildFeatureItem(Icons.lock_outline_rounded, 'Safe & Secure'),
          ],
        )
        .animate()
        .fadeIn(duration: 800.ms, delay: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTextSection() {
    return Column(
      children: [
        Text(
              'Life Partner Again',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            )
            .animate()
            .fadeIn(duration: 800.ms, delay: 600.ms)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Text(
              'Start your next chapter together',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 18,
                fontWeight: FontWeight.w300,
              ),
            )
            .animate()
            .fadeIn(duration: 800.ms, delay: 800.ms)
            .slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildCtaButton() {
    return CustomButton(
          text: 'Get Started',
          type: CustomButtonType.primary,
          borderRadius: 50,
          onPressed: () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => const SplashScreen(),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          },
        )
        .animate()
        .fadeIn(duration: 800.ms, delay: 1000.ms)
        .slideY(begin: 0.2, end: 0);
  }
}
