import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

class AgeStatusWidget extends StatelessWidget {
  final DateTime? dateOfBirth;

  const AgeStatusWidget({super.key, required this.dateOfBirth});

  @override
  Widget build(BuildContext context) {
    if (dateOfBirth == null) return const SizedBox.shrink();

    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;
    if (today.month < dateOfBirth!.month ||
        (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
      age--;
    }

    final isValid = age >= 18;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Column(
          key: ValueKey(age),
          children: [
            Text(
              "You're $age years old",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isValid ? AppColors.primary : AppColors.error,
              ),
            ),
            const SizedBox(height: 6),
            if (!isValid)
              Text(
                "Members must be aged 18 or over.",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error.withValues(alpha: 0.8),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Great! You're eligible to join.",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
