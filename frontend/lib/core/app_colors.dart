import 'package:flutter/material.dart';

class AppColors {
  // Common Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Colors.white;

  // Primary Brand Colors - Solid Red
  static const Color primary = Color(0xFFFF3F3F);
  static const Color primaryDark = Color(
    0xFFD63434,
  ); // Adjusted for contrast if needed
  static const Color primaryLight = Color(0xFFFF7A7A);

  // Accent Colors
  static const Color accent = Color(0xFFFF3F3F);

  // Status Colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);

  // ==========================================
  // Light Mode Colors (Legacy compatibility)
  // ==========================================
  static const Color background = Color(0xFFF2F2F2);
  static const Color surface = Colors.white;
  static const Color inputBackground = Color(0xFFFBFBFB);

  // Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textLight = Color(0xFF777777);
  static const Color textWhite = Colors.white;
  static const Color onPrimary = Colors.white;

  // UI Elements
  static const Color divider = Color(0xFFEAEAEA);
  static const Color unselectedIcon = Color(0xFF777777);
  static const Color shadowColor = Color(0x1F000000);
  static const Color borderColor = Color(0xFFEAEAEA);

  // ==========================================
  // Dark Mode Colors
  // ==========================================
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkInputBackground = Color(0xFF2C2C2C);

  // Dark Mode Text Colors
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkTextLight = Color(0xFF888888);

  // Dark Mode UI Elements
  static const Color darkDivider = Color(0xFF333333);
  static const Color darkUnselectedIcon = Color(0xFFAAAAAA);
  static const Color darkShadowColor = Color(0x33000000);
  static const Color darkBorderColor = Color(0xFF333333);
}
