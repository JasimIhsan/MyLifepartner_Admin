import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/shared/widgets/custom_button.dart';

class SubscriptionErrorWidget extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;

  const SubscriptionErrorWidget({super.key, required this.onRetry, this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔥 Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ).animate().fadeIn().scale(),

            const SizedBox(height: 24),

            // 🔥 Title
            Text(
              "Something went wrong",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 12),

            // 🔥 Friendly message
            Text(
              "We’re having trouble loading subscription plans right now.\nPlease try again in a moment.",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 16),

            // 🔥 Debug (optional)
            if (error != null)
              Text(
                error!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),

            // 🔥 Retry button
            CustomButton(
              onPressed: onRetry,
              text: "Retry",
              width: double.infinity,
              height: 50,
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
