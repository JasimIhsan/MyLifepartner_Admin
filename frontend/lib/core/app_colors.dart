import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Colors.deepPurple;
  static const Color primaryDark = Colors.indigo;
  static const Color primaryLight = Color(0xFFEDE7F6); // deepPurple.shade50

  // Background Colors
  static const Color background = Colors.white;
  static const Color surface = Colors.white;

  // Text Colors
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF757575); // Colors.grey[600]
  static const Color textWhite = Colors.white;

  // Status Colors
  static const Color error = Colors.redAccent;
  static const Color success = Colors.green;

  // UI Elements
  static const Color divider = Color(0xFFEEEEEE); // Colors.grey.shade100
  static const Color unselectedIcon = Colors.grey;
  static const Color shadowColor = Color(0x0D000000); // Black with low opacity
}
