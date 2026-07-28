import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/subscription_plan.dart' as model;

Future<void> showSubscriptionSuccessUI(
  BuildContext context,
  model.SubscriptionPlan plan,
) {
  if (kIsWeb) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          contentPadding: const EdgeInsets.all(32),
          content: SubscriptionSuccessUI(plan: plan),
        );
      },
    );
  } else {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: SubscriptionSuccessUI(plan: plan),
          ),
        );
      },
    );
  }
}

class SubscriptionSuccessUI extends StatelessWidget {
  final model.SubscriptionPlan plan;

  const SubscriptionSuccessUI({super.key, required this.plan});

  Widget _buildPerkRow(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: Colors.green,
          size: 22,
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gift Image
        Image.asset(
          'assets/images/illustrations/gift.png',
          height: 180,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 24),

        // Title
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            children: [
              TextSpan(
                text: 'Subscription\n',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              TextSpan(
                text: 'Successful!',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Subtitle
        const Text(
          'Welcome to Premium! You now have\naccess to all exclusive perks.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Perks Box
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _buildPerkRow('Unlimited likes'),
              const SizedBox(height: 16),
              _buildPerkRow('Chat without limits'),
              const SizedBox(height: 16),
              _buildPerkRow('See who liked you'),
              const SizedBox(height: 16),
              _buildPerkRow('Profile boost'),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Explore Now Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Explore Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Maybe later button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            splashFactory: NoSplash.splashFactory,
          ),
          child: const Text(
            'Maybe later',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
