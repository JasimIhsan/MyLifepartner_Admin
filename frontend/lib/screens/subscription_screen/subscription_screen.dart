import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mylifepartner/config/env.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/subscription_plan.dart' as model;
import 'package:mylifepartner/providers/subscription_provider.dart';
import 'package:mylifepartner/screens/subscription_screen/subscription_error_widget.dart';
import 'package:mylifepartner/shared/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    _initSubscriptions();
  }

  Future<void> _initSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    debugPrint("UserId from prefs: $userId");
    if (userId == 0) {
      debugPrint("Invalid userId");
      return;
    }

    if (!mounted) return;

    context.read<SubscriptionProvider>().loadSubscriptions(userId.toString());
  }

  void _handleSubscribe(model.SubscriptionPlan plan) async {
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
        builder: (context) => _buildCancelConfirmationSheet(),
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
              ? 'Successfully subscribed to ${plan.name}'
              : (provider.error ?? 'Failed to subscribe'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
    );
  }

  Widget _buildCancelConfirmationSheet() {
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
                  onPressed: () => Navigator.pop(context, true),
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
                  onPressed: () => Navigator.pop(context, false),
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
              return SubscriptionErrorWidget(
                error: provider.error,
                onRetry: _initSubscriptions,
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
                                  currentSub!.name,
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
                        currentSub != null && currentSub.id == plan.id;
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
                          ' / ${plan.rcDurationTitle ?? '${plan.durationDays} days'}',
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
