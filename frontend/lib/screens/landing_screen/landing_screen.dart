import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    // Using viewportFraction to allow siblings to be slightly visible
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
          children: [
            const SizedBox(height: 30),
            // Header Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    'Find Your\nPerfect Match',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Join thousands of others who have found love on Life Partner Again.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Stacked Card Carousel
            SizedBox(
              height: 400,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                clipBehavior: Clip.none, // Allow cards to overflow bounds slightly
                itemBuilder: (context, index) {
                  // Calculate the distance of the card from the center
                  double value = 0.0;
                  if (_pageController.position.haveDimensions) {
                    value = index - _currentPage;
                  } else {
                    value = (index - _currentPage).toDouble();
                  }

                  // 1. Scale down cards not in the center
                  double scale = max(0.8, 1 - (value.abs() * 0.15));
                  
                  // 2. Slant angle (rotate them slightly)
                  // Negative value means it's on the left, positive on the right
                  double angle = value * 0.15; 
                  
                  // 3. Translation to force them to overlap (stack)
                  // Pull the side cards closer to the center
                  double translateX = -value * 60; 
                  // Push the side cards slightly down
                  double translateY = value.abs() * 30;

                  // 4. Opacity fade for background cards
                  double opacity = max(0.5, 1 - (value.abs() * 0.4));

                  // 5. Determine z-index equivalent (not strictly z-index, but visual stacking)
                  // The center card should appear on top, handled implicitly by rendering order
                  // and translation. Because later items in ListView render on top, we might
                  // have a slight stacking anomaly, but standard Transform manages it decently.

                  return Transform.translate(
                    offset: Offset(translateX, translateY),
                    child: Transform.rotate(
                      angle: angle,
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Image or Placeholder
                                  _buildImage(index),
                                  // Subtle gradient overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.2),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const Spacer(),
            
            // Golden Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const SplashScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.golden,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                ),
                child: Text(
                  'Get Started',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildImage(int index) {
    return Image.asset(
      _images[index % _images.length],
      fit: BoxFit.cover,
    );
  }
}
