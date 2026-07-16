import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/config/env.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/subscription_plan.dart' as model;
import 'package:life_partner_again/providers/subscription_provider.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlanVisuals {
  final Color themeColor;
  final Color borderColor;
  final Color bgColor;
  final List<Color> gradientColors;
  final bool isPopular;
  final String? badgeText;

  PlanVisuals({
    required this.themeColor,
    required this.borderColor,
    required this.bgColor,
    required this.gradientColors,
    required this.isPopular,
    required this.badgeText,
  });
}

mixin SubscriptionControllerState<T extends StatefulWidget> on State<T> {
  void initSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    debugPrint("UserId from prefs: \$userId");
    if (userId == 0) {
      debugPrint("Invalid userId");
      return;
    }

    if (!mounted) return;

    context.read<SubscriptionProvider>().loadSubscriptions(userId.toString());
  }

  void handleSubscribe(model.SubscriptionPlan plan) async {
    final provider = context.read<SubscriptionProvider>();

    if (plan.price == 0 &&
        provider.currentSubscription != null &&
        provider.currentSubscription!.price > 0) {
      final confirm = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => buildCancelConfirmationSheet(),
      );

      if (confirm != true) return;
    }

    final success = await provider.subscribeToPlan(
      plan.identifier ?? plan.id.toString(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Successfully subscribed to \${plan.name}'
              : (provider.error ?? 'Failed to subscribe'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
    );
  }

  Widget buildCancelConfirmationSheet() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Cancel Subscription?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Are you sure you want to cancel your premium plan? You will lose access to all premium features immediately.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  onPressed: () => context.pop(true),
                  text: 'Yes, Cancel',
                  type: CustomButtonType.outline,
                  backgroundColor: AppColors.surface,
                  textColor: AppColors.textPrimary,
                  height: 52,
                  borderRadius: 16,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  onPressed: () => context.pop(false),
                  text: 'Keep Plan',
                  type: CustomButtonType.primary,
                  backgroundColor: AppColors.primary,
                  textColor: Colors.white,
                  height: 52,
                  borderRadius: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> initRevenueCat() async {
    await Purchases.configure(PurchasesConfiguration(Env.revenueCatApiKey));
  }

  PlanVisuals getPlanVisuals(model.SubscriptionPlan plan) {
    if (plan.price == 0) {
      return PlanVisuals(
        themeColor: AppColors.textLight,
        borderColor: AppColors.borderColor,
        bgColor: AppColors.background,
        gradientColors: const [Color(0xFF94A3B8), Color(0xFF64748B)],
        isPopular: false,
        badgeText: null,
      );
    }

    final nameLower = plan.name.toLowerCase();
    if (plan.isMostPopular) {
      return PlanVisuals(
        themeColor: AppColors.primary,
        borderColor: AppColors.primaryLight,
        bgColor: const Color(0xFFF8FAFC),
        gradientColors: const [AppColors.primaryLight, AppColors.primary],
        isPopular: true,
        badgeText: 'Most Popular',
      );
    } else if (nameLower.contains('yearly') || nameLower.contains('annual')) {
      return PlanVisuals(
        themeColor: AppColors.primary,
        borderColor: AppColors.primaryLight,
        bgColor: const Color(0xFFF8FAFC),
        gradientColors: const [AppColors.primaryLight, AppColors.primaryDark],
        isPopular: false,
        badgeText: '40% OFF',
      );
    } else {
      return PlanVisuals(
        themeColor: AppColors.primary,
        borderColor: AppColors.borderColor,
        bgColor: const Color(0xFFF8FAFC),
        gradientColors: const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
        isPopular: false,
        badgeText: null,
      );
    }
  }
}
