import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/models/subscription_plan.dart' as model;
import 'package:life_partner_again/providers/subscription_provider.dart';
import 'package:life_partner_again/screens/subscription_screen/subscription_background_painter.dart';
import 'package:life_partner_again/screens/subscription_screen/subscription_error_widget.dart';
import 'package:life_partner_again/screens/subscription_screen/widgets/subscription_controller.dart';
import 'package:life_partner_again/screens/subscription_screen/widgets/subscription_ui_helpers.dart';
import 'package:provider/provider.dart';

class WebSubscriptionScreen extends StatefulWidget {
  const WebSubscriptionScreen({super.key});

  @override
  State<WebSubscriptionScreen> createState() => _WebSubscriptionScreenState();
}

class _WebSubscriptionScreenState extends State<WebSubscriptionScreen>
    with SubscriptionControllerState<WebSubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    initSubscriptions();
  }

  void _showPlanDetailsSheet(
    BuildContext context,
    model.SubscriptionPlan plan,
  ) {
    final List<String> displayFeatures;
    if (plan.price == 0) {
      displayFeatures = [
        'Basic profile access only',
        'Upgrade to send interests',
        'Upgrade to start chatting',
        'Upgrade for video & audio calls',
      ];
    } else if (plan.name.toLowerCase().contains('yearly') ||
        plan.name.toLowerCase().contains('annual')) {
      displayFeatures = [
        'All Premium benefits',
        'Better visibility',
        'Priority support',
      ];
    } else {
      displayFeatures = [
        'Access All Premium Features',
        'Send Interests to Any Profile',
        'Chat with Interested Members',
        'Unlimited Video Calls',
        'Unlimited Audio Calls',
      ];
    }

    showDialog(
      context: context,
      builder: (context) {
        final provider = context.read<SubscriptionProvider>();
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\${plan.name} Plan Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: provider.hasBillingIssue
                        ? const Color(0xFFFEF2F2)
                        : (provider.isInGracePeriod
                              ? const Color(0xFFFFFBEB)
                              : Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: provider.hasBillingIssue
                          ? const Color(0xFFFCA5A5)
                          : (provider.isInGracePeriod
                                ? const Color(0xFFFCD34D)
                                : Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.currentSubscriptionMessage ??
                            'Your subscription is active.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: provider.hasBillingIssue
                              ? const Color(0xFFDC2626)
                              : (provider.isInGracePeriod
                                    ? const Color(0xFFD97706)
                                    : Theme.of(context).primaryColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Price: \${plan.displayPrice}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                              Theme.of(context).textTheme.bodyMedium?.color ??
                              Theme.of(context).textTheme.bodyMedium?.color ??
                              Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Included Limits & Features:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color:
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ...displayFeatures.map(
                  (feat) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          feat,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsAndPrivacy(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 48.0,
        vertical: 24.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Container(
                      width: 600,
                      height: 500,
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Terms & Privacy Policy',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => context.pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: ListView(
                              children: [
                                const Text(
                                  'Terms of Service',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Welcome to Life Partner Again. By subscribing to our premium plans, you agree to comply with and be bound by our general terms of service. Subscriptions automatically renew at the end of the billing period unless cancelled at least 24 hours prior to renewal.',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'We take your privacy seriously. We store your account details securely and process payments through safe systems (RevenueCat, App Store, Google Play). Your profile image and educational history are used solely to improve connections and match preferences. You can manage photo blurring and profile privacy settings directly from your settings panel.',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Subscription Management',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You can upgrade, downgrade, or cancel your active subscription anytime. Downgrades take effect at the end of the current billing cycle. Refunds are managed directly by your respective App Store.',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: Text(
              'Terms & Privacy',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.plans.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
          }

          if (provider.error != null && provider.plans.isEmpty) {
            return SubscriptionErrorWidget(
              error: provider.error,
              onRetry: initSubscriptions,
            );
          }

          final plans = provider.plans;
          final currentSub = provider.currentSubscription;

          return Stack(
            children: [
              const SubscriptionBackground(),
              Positioned(
                top: -150,
                right: -80,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFCBD5E1).withValues(alpha: 0.25),
                        const Color(0xFFE2E8F0).withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                              ),
                              onPressed: () => context.pop(),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Choose Your Plan',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.receipt_long_rounded,
                                color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                                size: 28,
                              ),
                              onPressed: () => context.push(AppRoutes.billingHistory),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Unlock Premium Perks',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Premium perks to help you find your perfect life partner.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 48),
                              if (plans.isNotEmpty)
                                Center(
                                  child: Wrap(
                                    spacing: 32,
                                    runSpacing: 32,
                                    alignment: WrapAlignment.center,
                                    children: plans.map((plan) {
                                      final isCurrentPlan =
                                          currentSub != null &&
                                          currentSub.id == plan.id;
                                      final visuals = getPlanVisuals(plan);

                                      return SizedBox(
                                        width: 320,
                                        height: 450,
                                        child: PlanCardWidget(
                                          plan: plan,
                                          isCurrentPlan: isCurrentPlan,
                                          isLoading: provider.isLoading,
                                          isSelectedPage: false,
                                          willRenew: provider.mySubscription?.willRenew ?? true,
                                          visuals: visuals,
                                          hasBillingIssue: isCurrentPlan ? provider.hasBillingIssue : false,
                                          isInGracePeriod: isCurrentPlan ? provider.isInGracePeriod : false,
                                          isCancelledButActive: isCurrentPlan ? provider.isCancelledButActive : false,
                                          isDowngradeScheduled: isCurrentPlan ? provider.isDowngradeScheduled : false,
                                          isCancelled: isCurrentPlan ? provider.isCancelled : false,
                                          onSubscribe: () {
                                            if (isCurrentPlan && plan.price > 0) {
                                              handleSubscribe(
                                                provider.plans.firstWhere(
                                                  (p) => p.price == 0,
                                                ),
                                              );
                                            } else {
                                              handleSubscribe(plan);
                                            }
                                          },
                                          onInfoTap: () =>
                                              _showPlanDetailsSheet(
                                                context,
                                                plan,
                                              ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: Text(
                                    'No subscription plans available.',
                                  ),
                                ),
                              const SizedBox(height: 48),
                              _buildTermsAndPrivacy(context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
