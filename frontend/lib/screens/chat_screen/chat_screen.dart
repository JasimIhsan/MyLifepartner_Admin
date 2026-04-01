import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';

class ChatPlaceholderScreen extends StatelessWidget {
  const ChatPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.message_outlined, size: 36),
          ),
          const SizedBox(height: 24),
          Text(
            'Messages coming soon!',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your matches.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
