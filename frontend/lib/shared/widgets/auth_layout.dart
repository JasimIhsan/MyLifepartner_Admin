import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';

class AuthLayout extends StatelessWidget {
  final Widget child;
  final bool showLogo;
  final String? title;
  final String? topImage;

  const AuthLayout({
    super.key,
    required this.child,
    this.showLogo = true,
    this.title,
    this.topImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWeb = constraints.maxWidth > 900;
          final size = MediaQuery.of(context).size;

          if (isWeb) {
            return _buildWebLayout(size);
          }
          return _buildMobileLayout(size);
        },
      ),
    );
  }

  Widget _buildWebLayout(Size size) {
    return Row(
      children: [
        // Left Side - Info
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "lifepartneragain",
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "A trusted platform for emotionally\nmature relationships.",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Side - Form
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 60.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(true),
                      const SizedBox(height: 24),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Size size) {
    return SizedBox(
      width: double.infinity,
      height: size.height,
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (topImage != null)
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Image.asset(
                    topImage!,
                    width: double.infinity,
                    height: size.height * 0.45,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  Container(
                    height: size.height * 0.2, // Gradient fade area
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.background.withValues(alpha: 0.0),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            
            Transform.translate(
              offset: Offset(0, topImage != null ? -45.0 : 0.0),
              child: SafeArea(
                top: topImage == null, // Only avoid notch if no top image bleeds into it
                bottom: false,
                left: false,
                right: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (topImage == null) const SizedBox(height: 40),
                      // Title Section
                      if (showLogo) ...[
                        if (topImage != null) ...[
                          const SizedBox(
                            width: 90,
                            height: 90,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Life Partner Again",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ] else ...[
                          Text(
                            "lifepartneragain",
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          "A trusted platform for emotionally\nmature relationships.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Content
                      child,
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWeb) {
    if (!isWeb) return const SizedBox.shrink(); // Only for Web now
    return Column(
      children: [
        Text(
          "Life Partner Again",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            "A trusted platform for emotionally\nmature relationships.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
