import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../splash_screen/splash_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  late PageController _pageController;
  double _currentPage = 0.0;

  final List<String> _images = [
    'assets/images/landing_couple_1.png',
    'assets/images/landing_couple_2.png',
    'assets/images/landing_couple_3.png',
  ];

  // Taglines that cycle with the carousel
  final List<String> _taglines = [
    'Every story begins\nwith a single moment.',
    'Crafted for those who\nbelieve in forever.',
    'Your next chapter\nstarts here.',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.65);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _activePage => _currentPage.round().clamp(0, _images.length - 1);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              _buildHeader(),
              const SizedBox(height: 8),
              _buildSubtitle(),
              const SizedBox(height: 36),
              _buildCarousel(),
              const SizedBox(height: 20),
              _buildDots(),
              const Spacer(),
              _buildCta(),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App label
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Life Partner',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 100.ms)
              .slideY(begin: -0.2, end: 0, curve: Curves.easeOut),
          const SizedBox(height: 14),
          // Main headline
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            ),
            child: Text(
              _taglines[_activePage],
              key: ValueKey(_activePage),
              style: GoogleFonts.cormorantGaramond(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.18,
                letterSpacing: -0.5,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 700.ms, delay: 200.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  // ─── Subtitle ──────────────────────────────────────────────────────────────

  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Text(
        'Join thousands who found their match —\ncurated, genuine, and built to last.',
        style: GoogleFonts.lato(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.7,
          letterSpacing: 0.1,
        ),
      )
          .animate()
          .fadeIn(duration: 600.ms, delay: 350.ms)
          .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
    );
  }

  // ─── Carousel ──────────────────────────────────────────────────────────────

  Widget _buildCarousel() {
    return SizedBox(
      height: 380,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _images.length,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          double value = 0.0;
          if (_pageController.position.haveDimensions) {
            value = index - _currentPage;
          } else {
            value = (index - _currentPage).toDouble();
          }

          final double scale = max(0.82, 1 - (value.abs() * 0.13));
          final double angle = value * 0.12;
          final double translateX = -value * 55;
          final double translateY = value.abs() * 24;
          final double opacity = max(0.45, 1 - (value.abs() * 0.45));
          final bool isActive = index == _activePage;

          return Transform.translate(
            offset: Offset(translateX, translateY),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: _buildCard(index, isActive),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 800.ms, delay: 400.ms).slideY(
        begin: 0.06, end: 0, duration: 700.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildCard(int index, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isActive ? 0.18 : 0.08),
            blurRadius: isActive ? 32 : 16,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            Image.asset(
              _images[index % _images.length],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFEEEEEE),
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      size: 48, color: Color(0xFFCCCCCC)),
                ),
              ),
            ),
            // Bottom gradient — deeper on active
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(
                          alpha: isActive ? 0.55 : 0.2),
                    ],
                  ),
                ),
              ),
            ),
            // Index pill — only on active
            if (isActive)
              Positioned(
                bottom: 18,
                left: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${index + 1} of ${_images.length}',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Dot indicators ────────────────────────────────────────────────────────

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_images.length, (i) {
        final bool active = i == _activePage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.black : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }),
    ).animate().fadeIn(duration: 500.ms, delay: 600.ms);
  }

  // ─── CTA Button ────────────────────────────────────────────────────────────

  Widget _buildCta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          // Primary CTA
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => const SplashScreen(),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 500),
              ),
            ),
            child: Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Get Started',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Fine-print
          Text(
            'Free to join · No hidden fees',
            style: GoogleFonts.lato(
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 700.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }
}
