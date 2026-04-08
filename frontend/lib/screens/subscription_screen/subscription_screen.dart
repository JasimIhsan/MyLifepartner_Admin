import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/subscription_plan.dart' as model;
import 'package:mylifepartner/providers/subscription_provider.dart';
import 'package:mylifepartner/shared/widgets/custom_button.dart';
import 'package:provider/provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SubscriptionProvider>();
      provider.fetchPlans();
      provider.fetchMySubscription();
    });
  }

  void _handleSubscribe(model.SubscriptionPlan plan) async {
    final provider = context.read<SubscriptionProvider>();
    final success = await provider.subscribeToPlan(plan.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully subscribed to ${plan.name}'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to subscribe'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose Your Plan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Consumer<SubscriptionProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.plans.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (provider.error != null && provider.plans.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.error!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        onPressed: provider.fetchPlans,
                        text: 'Retry',
                      ),
                    ],
                  ),
                ),
              );
            }

            final plans = provider.plans;
            final currentSub = provider.currentSubscription;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                        'Unlock Premium Features',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 8),
                  Text(
                        'Choose a plan that fits your needs and start your journey towards finding your life partner.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 32),
                  if (currentSub?.isActive ?? false) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Active Plan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  currentSub!.plan?.name ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 24),
                  ],
                  ...plans.asMap().entries.map((entry) {
                    final index = entry.key;
                    final plan = entry.value;
                    final isCurrentPlan =
                        currentSub?.isActive == true &&
                        currentSub?.planId == plan.id;
                    return _buildPlanCard(
                          plan,
                          isCurrentPlan,
                          provider.isLoading,
                        )
                        .animate()
                        .fadeIn(
                          delay: (400 + (index * 100)).ms,
                          duration: 500.ms,
                        )
                        .slideX(begin: 0.1, end: 0);
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    model.SubscriptionPlan plan,
    bool isCurrentPlan,
    bool isLoading,
  ) {
    final isPopular = plan.isMostPopular;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isPopular ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular
              ? AppColors.primary
              : isCurrentPlan
              ? AppColors.primary
              : AppColors.borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isPopular && !isCurrentPlan)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.onPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          if (isCurrentPlan)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.onPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isPopular
                        ? AppColors.onPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (plan.price > 0)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.displayPrice,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isPopular
                              ? AppColors.onPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5, left: 4),
                        child: Text(
                          ' / ${plan.durationDays} days',
                          style: TextStyle(
                            fontSize: 14,
                            color: isPopular
                                ? AppColors.onPrimary.withValues(alpha: 0.7)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Get Started Free',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isPopular
                          ? AppColors.onPrimary
                          : AppColors.primary,
                    ),
                  ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 24),
                ...plan.featureDescriptions.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: isPopular
                              ? AppColors.onPrimary
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 14,
                              color: isPopular
                                  ? AppColors.onPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  onPressed: isCurrentPlan || isLoading
                      ? () {}
                      : () => _handleSubscribe(plan),
                  text: Theme.of(context).platform == TargetPlatform.iOS
                      ? (isCurrentPlan
                            ? 'Current Plan'
                            : isLoading
                            ? 'Processing...'
                            : 'Select ${plan.name}')
                      : (isCurrentPlan
                            ? 'Current Plan'
                            : isLoading
                            ? 'Processing...'
                            : 'Select ${plan.name}'),
                  type: isPopular
                      ? CustomButtonType.primary
                      : CustomButtonType.outline,
                  backgroundColor: isPopular
                      ? AppColors.onPrimary
                      : AppColors.primary,
                  textColor: isPopular ? AppColors.primary : AppColors.primary,
                  width: double.infinity,
                  borderRadius: 16,
                  height: 52,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
