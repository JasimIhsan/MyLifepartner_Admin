import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_colors.dart';

class OtpHeader extends StatelessWidget {
  final String verificationMethod;
  final String phoneNumber;
  final String code;
  final bool isWeb;

  const OtpHeader({
    super.key,
    required this.isWeb,
    required this.code,
    required this.verificationMethod,
    required this.phoneNumber,
  });

  String get _maskedPhoneNumber {
    if (phoneNumber.length <= 4) return phoneNumber;
    return "$code******${phoneNumber.substring(phoneNumber.length - 4)}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter Verification Code",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            text:
                "We’ve sent a 6-digit verification code via $verificationMethod to ",
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[600]),
            children: [
              TextSpan(
                text: "$_maskedPhoneNumber.",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OtpWebBanner extends StatelessWidget {
  final String verificationMethod;

  const OtpWebBanner({super.key, required this.verificationMethod});

  @override
  Widget build(BuildContext context) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 1000),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_rounded, size: 150, color: AppColors.primary),
            const SizedBox(height: 32),
            Text(
              "Account Verification",
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "We've sent a 6-digit code via $verificationMethod to your phone. Please enter it to verify your identity.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
