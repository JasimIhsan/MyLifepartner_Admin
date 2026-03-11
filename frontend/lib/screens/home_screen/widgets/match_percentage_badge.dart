import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mylifepartner/core/app_colors.dart';

class MatchPercentageBadge extends StatelessWidget {
  final int percentage;

  const MatchPercentageBadge({super.key, required this.percentage});

  Color _badgeColor() {
    if (percentage >= 90) return AppColors.matchHigh;
    if (percentage >= 80) return AppColors.matchMedium;
    return AppColors.matchLow;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _badgeColor(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _badgeColor().withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, color: AppColors.textWhite, size: 13),
          const SizedBox(width: 4),
          Text(
            '$percentage% Match',
            style: const TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.elasticOut);
  }
}
