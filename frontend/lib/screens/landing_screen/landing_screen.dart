import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';
import 'package:life_partner_again/providers/image_asset_provider.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:provider/provider.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: MobileLandingScreen(),
      web: WebLandingScreen(),
    );
  }
}

class MobileLandingScreen extends StatefulWidget {
  const MobileLandingScreen({super.key});

  @override
  State<MobileLandingScreen> createState() => _MobileLandingScreenState();
}

class _MobileLandingScreenState extends State<MobileLandingScreen> {
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
        backgroundColor: Colors.black,
        body: Consumer<ImageAssetProvider>(
          builder: (context, provider, child) {
            final state = provider.getState('ONBOARDING_SCREEN');
            final landingAsset = provider.getFeaturedAsset('ONBOARDING_SCREEN');

            return Stack(
              children: [
                Positioned.fill(
                  child: state == ImageAssetLoadState.loading
                      ? Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : (landingAsset != null
                            ? CachedNetworkImage(
                                imageUrl: landingAsset.imageUrl,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                errorWidget: (context, url, error) =>
                                    _buildDefaultBackground(),
                              )
                            : _buildDefaultBackground()),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.95),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildLogo(),
                        const Spacer(),
                        _buildTextSection(),
                        const SizedBox(height: 32),
                        _buildTrustCards(),
                        const SizedBox(height: 40),
                        _buildCtaButton(),
                        const SizedBox(height: 32),
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
      alignment: Alignment.topCenter,
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
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Image.asset(
        'assets/icons/app_logo.png',
        height: 100,
        width: 100,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.favorite_rounded,
          color: AppColors.primary,
          size: 80,
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildTextSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
              'Find your life\npartner again.',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.1,
                letterSpacing: -1.0,
              ),
            )
            .animate()
            .fadeIn(duration: 800.ms, delay: 200.ms)
            .slideY(begin: 0.1, end: 0),
        const SizedBox(height: 16),
        Text(
              'A trusted platform designed for emotionally mature relationships and authentic connections.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            )
            .animate()
            .fadeIn(duration: 800.ms, delay: 400.ms)
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildTrustCards() {
    return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildTrustCard(Icons.verified_user_rounded, 'Verified'),
            _buildTrustCard(Icons.shield_rounded, 'Privacy'),
            _buildTrustCard(Icons.lock_rounded, 'Secure'),
          ],
        )
        .animate()
        .fadeIn(duration: 800.ms, delay: 600.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildTrustCard(IconData icon, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCtaButton() {
    return SizedBox(
          width: double.infinity,
          height: 60,
          child: CustomButton(
            text: 'Get Started',
            type: CustomButtonType.primary,
            borderRadius: 30,
            onPressed: () {
              context.go(AppRoutes.login);
            },
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms, delay: 800.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImageAssetProvider>().loadAssets('ONBOARDING_SCREEN');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Row(
        children: [
          // Left column - Premium Image and Gradient
          Expanded(
            flex: 6,
            child: Consumer<ImageAssetProvider>(
              builder: (context, provider, child) {
                final state = provider.getState('ONBOARDING_SCREEN');
                final landingAsset = provider.getFeaturedAsset(
                  'ONBOARDING_SCREEN',
                );

                return Stack(
                  children: [
                    Positioned.fill(
                      child: state == ImageAssetLoadState.loading
                          ? Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : (landingAsset != null
                                ? CachedNetworkImage(
                                    imageUrl: landingAsset.imageUrl,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    errorWidget: (context, url, error) =>
                                        _buildDefaultBackground(),
                                  )
                                : _buildDefaultBackground()),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.8),
                            ],
                            stops: const [0.3, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 80,
                      left: 80,
                      right: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                                "Find a connection that lasts a lifetime.",
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              )
                              .animate()
                              .fadeIn(duration: 800.ms)
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: 16),
                          Text(
                                "A trusted platform designed for emotionally mature relationships. Join us and discover depth, companionship, and authentic connections.",
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                              )
                              .animate()
                              .fadeIn(duration: 800.ms, delay: 200.ms)
                              .slideY(begin: 0.2, end: 0),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Right column - Control Panel
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child:
                            Image.asset(
                                  'assets/icons/app_logo.png',
                                  height: 120,
                                  width: 120,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.favorite_rounded,
                                        color: AppColors.primary,
                                        size: 80,
                                      ),
                                )
                                .animate()
                                .fadeIn(duration: 800.ms)
                                .scale(begin: const Offset(0.9, 0.9)),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        'Life Partner Again',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                      ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
                      const SizedBox(height: 12),
                      Text(
                        'Start your next chapter together. Sign in to connect with compatible and verified partners.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.black54),
                      ).animate().fadeIn(duration: 800.ms, delay: 400.ms),
                      const SizedBox(height: 48),
                      // Feature Badges
                      Column(
                        children: [
                          _buildFeatureRow(
                            Icons.verified_user_outlined,
                            'Verified Profiles',
                            'Every profile is checked for safety and authenticity.',
                          ),
                          const SizedBox(height: 20),
                          _buildFeatureRow(
                            Icons.favorite_outline_rounded,
                            'Real Love & Intention',
                            'Designed exclusively for deep, emotionally mature bonds.',
                          ),
                          const SizedBox(height: 20),
                          _buildFeatureRow(
                            Icons.lock_outline_rounded,
                            'Safe & Secure',
                            'Your privacy is prioritized with end-to-end encryption.',
                          ),
                        ],
                      ).animate().fadeIn(duration: 800.ms, delay: 600.ms),
                      const SizedBox(height: 54),
                      SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: 'Get Started',
                              type: CustomButtonType.primary,
                              borderRadius: 12,
                              height: 56,
                              onPressed: () {
                                context.go(AppRoutes.login);
                              },
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 800.ms)
                          .slideY(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultBackground() {
    return Image.asset(
      'assets/images/landing_couple.png',
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) =>
          Container(color: Colors.grey[900]),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
