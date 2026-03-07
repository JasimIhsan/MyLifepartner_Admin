import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MatchPercentageBadge extends StatelessWidget {
  final int percentage;

  const MatchPercentageBadge({super.key, required this.percentage});

  Color _badgeColor() {
    if (percentage >= 90) return const Color(0xFF1A6B3A); // dark green
    if (percentage >= 80) return const Color(0xFF2E8B57); // green
    return const Color(0xFF5CB85C); // light green
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
            color: _badgeColor().withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            '$percentage% Match',
            style: const TextStyle(
              color: Colors.white,
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
