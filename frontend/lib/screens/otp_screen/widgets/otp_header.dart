import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';

class OtpHeader extends StatelessWidget {
  final String email;
  final bool isWeb;
  final bool isPasswordReset;

  const OtpHeader({
    super.key,
    required this.isWeb,
    required this.email,
    this.isPasswordReset = false,
  });

  String get _maskedEmail {
    if (email.length <= 4 || !email.contains('@')) return email;
    final parts = email.split('@');
    if (parts[0].length <= 2) return "${parts[0]}***@${parts[1]}";
    return "${parts[0].substring(0, 2)}***@${parts[1]}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isPasswordReset ? "Reset Password" : "Enter Verification Code",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            text: isPasswordReset
                ? "We’ve sent a 6-digit password reset code to "
                : "We’ve sent a 6-digit verification code to ",
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[600]),
            children: [
              TextSpan(
                text: "$_maskedEmail.",
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
  const OtpWebBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            "We've sent a 6-digit code to your email. Please enter it to verify your identity.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
