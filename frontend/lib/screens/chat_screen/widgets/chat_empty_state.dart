import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.waving_hand_rounded, color: Colors.orangeAccent, size: 48),
          SizedBox(height: 16),
          Text(
            'Say hi!',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Don\'t be shy, start the conversation.',
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}