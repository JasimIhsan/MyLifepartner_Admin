import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFFB88973);
  static const Color primaryDark = Color(0xFF8D6E63);
  static const Color primaryLight = Color(0xFFFBEFEA); // Light brownish tint

  // Background Colors
  static const Color background = Color(0xFFFDF5F2);
  static const Color surface = Colors.white;
  static const Color inputBackground = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF4E342E); // Dark brown-black
  static const Color textSecondary = Color(0xFF757575); // Colors.grey[600]
  static const Color textWhite = Colors.white;
  static const Color onPrimary = Colors.white;

  // Status Colors
  static const Color error = Colors.redAccent;
  static const Color success = Colors.green;

  // UI Elements
  static const Color divider = Color(0xFFEEEEEE); // Colors.grey.shade100
  static const Color unselectedIcon = Colors.grey;
  static const Color shadowColor = Color(0x0D000000); // Black with low opacity
  static const Color borderColor = Color(0xFFE0E0E0);

  // Match Indication Colors
  static const Color matchHigh = Color(0xFF1A6B3A); // dark green
  static const Color matchMedium = Color(0xFF2E8B57); // green
  static const Color matchLow = Color(0xFF5CB85C); // light green

  // Action Button Colors
  static const Color actionReject = Color(0xFFFF5252);
  static const Color actionSkip = Color(0xFF9E9E9E);
  static const Color actionAccept = Color(0xFF4CAF50);

  // Widget specific colors
  static const Color carouselBackground = Color(0xFF2D2D3A);
  static const Color highlightBackground = Color(0xFFF8F9FA); // Off-white
  static const Color highlightTagBackground = Color(0xFFE8F5E9); // light green tint
  static const Color highlightTagText = Color(0xFF2E7D32); // Dark green
  static const Color transparentOverlay = Color(0xDD000000); // Black with transparency
}
