import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../login_screen/login_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine if we are on a "web" (wide) screen or mobile
            final bool isWeb = constraints.maxWidth > 900;
            final size = MediaQuery.of(context).size;

            debugPrint("Size: $size");
            debugPrint("Constraints: $constraints");

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 80.0 : 24.0,
                    vertical: 30.0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: isWeb
                          ? _buildWebLayout(context, size)
                          : _buildMobileLayout(context, size, constraints),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext ctx, Size size) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 5, child: _buildHeroSection(ctx, size, true)),
        const SizedBox(width: 80),
        Expanded(flex: 4, child: _buildContentSection(ctx, true)),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext ctx,
    Size size,
    BoxConstraints constraints,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildHeroSection(ctx, size, false),
        const SizedBox(height: 30),
        _buildContentSection(ctx, false),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext ctx, size, bool isWeb) {
    return FadeInDown(
      duration: const Duration(milliseconds: 1200),
      child: Container(
        height: isWeb ? size.height * 0.7 : size.height * 0.45,
        constraints: isWeb ? const BoxConstraints(minHeight: 500) : null,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Image.asset(
          "assets/icons/app_logo.png",
          height: 100,
          width: 100,
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext ctx, bool isWeb) {
    return FadeInUp(
      duration: const Duration(milliseconds: 1200),
      delay: const Duration(milliseconds: 200),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: isWeb
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Text(
            "Connect with people\nwho share your values",
            textAlign: isWeb ? TextAlign.left : TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isWeb ? 42 : 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Join the community of millions of people who have found their life partner.",
            textAlign: isWeb ? TextAlign.left : TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isWeb ? 18 : 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: isWeb ? 300 : double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: Text(
                "Get Started",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
