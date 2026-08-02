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
      displayFeatures = ['Limited matches', 'Basic search'];
    } else if (plan.name.toLowerCase().contains('yearly') ||
        plan.name.toLowerCase().contains('annual')) {
      displayFeatures = [
        'All Premium benefits',
        'Better visibility',
        'Priority support',
      ];
    } else {
      displayFeatures = [
        'Unlimited likes',
        'Chat without limits',
        'See who liked you',
        'Profile boost',
      ];
    }

    showDialog(
      context: context,
      builder: (context) {
        final provider = context.read<SubscriptionProvider>();
        return Dialog(
          backgroundColor: AppColors.surface,
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
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
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.currentSubscriptionMessage ??
                            'Your subscription is active.',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Price: \${plan.displayPrice}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Included Limits & Features:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ...displayFeatures.map(
                  (feat) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          feat,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.plans.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
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
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppColors.textPrimary,
                              ),
                              onPressed: () => context.pop(),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Choose Your Plan',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.receipt_long_rounded,
                                color: AppColors.textPrimary,
                                size: 28,
                              ),
                              onPressed: () =>
                                  context.push(AppRoutes.transactionHistory),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Unlock Premium Perks',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Premium perks to help you find your perfect life partner.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
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
                                        height:
                                            450, // Fixed height for alignment
                                        child: PlanCardWidget(
                                          plan: plan,
                                          isCurrentPlan: isCurrentPlan,
                                          isLoading: provider.isLoading,
                                          isSelectedPage:
                                              false, // For web, no scaling down
                                          willRenew:
                                              provider
                                                  .mySubscription
                                                  ?.willRenew ??
                                              true,
                                          visuals: visuals,
                                          hasBillingIssue: isCurrentPlan ? provider.hasBillingIssue : false,
                                          isInGracePeriod: isCurrentPlan ? provider.isInGracePeriod : false,
                                          isCancelledButActive: isCurrentPlan ? provider.isCancelledButActive : false,
                                          onSubscribe: () {
                                            if (isCurrentPlan &&
                                                plan.price > 0) {
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
                            ],
                          ),
                        ),
                      ),
                      // Footer
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48.0,
                          vertical: 24.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // TextButton(
                            //   onPressed: () async {
                            //     final provider = context
                            //         .read<SubscriptionProvider>();
                            //     if (provider.mySubscription != null &&
                            //         !provider.mySubscription!.willRenew) {
                            //       ScaffoldMessenger.of(context).showSnackBar(
                            //         const SnackBar(
                            //           content: Text(
                            //             'Your plan is already cancelled and will downgrade on expiration.',
                            //           ),
                            //           backgroundColor: Colors.black,
                            //         ),
                            //       );
                            //       return;
                            //     }

                            //     if (provider.currentSubscription == null ||
                            //         provider.currentSubscription!.price == 0) {
                            //       ScaffoldMessenger.of(context).showSnackBar(
                            //         const SnackBar(
                            //           content: Text(
                            //             'You are already on the Free plan.',
                            //           ),
                            //           backgroundColor: Colors.black,
                            //         ),
                            //       );
                            //       return;
                            //     }

                            //     final confirm = await showDialog<bool>(
                            //       context: context,
                            //       builder: (context) => Dialog(
                            //         backgroundColor: AppColors.surface,
                            //         shape: RoundedRectangleBorder(
                            //           borderRadius: BorderRadius.circular(24),
                            //         ),
                            //         child: SizedBox(
                            //           width: 400,
                            //           child: buildCancelConfirmationSheet(),
                            //         ),
                            //       ),
                            //     );

                            //     if (confirm == true) {
                            //       final freePlan = provider.plans.firstWhere(
                            //         (p) => p.price == 0,
                            //       );
                            //       handleSubscribe(freePlan);
                            //     }
                            //   },
                            //   child: const Text(
                            //     'Restore Subscription',
                            //     style: TextStyle(
                            //       color: AppColors.primary,
                            //       fontSize: 14,
                            //       fontWeight: FontWeight.bold,
                            //     ),
                            //   ),
                            // ),
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Dialog(
                                      backgroundColor: AppColors.surface,
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Terms & Privacy Policy',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close),
                                                  onPressed: () =>
                                                      context.pop(),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 24),
                                            Expanded(
                                              child: ListView(
                                                children: const [
                                                  Text(
                                                    'Terms of Service',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Welcome to Life Partner Again. By subscribing to our premium plans, you agree to comply with and be bound by our general terms of service. Subscriptions automatically renew at the end of the billing period unless cancelled at least 24 hours prior to renewal.',
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                  SizedBox(height: 24),
                                                  Text(
                                                    'Privacy Policy',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'We take your privacy seriously. We store your account details securely and process payments through safe systems (RevenueCat, App Store, Google Play). Your profile image and educational history are used solely to improve connections and match preferences. You can manage photo blurring and profile privacy settings directly from your settings panel.',
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                  SizedBox(height: 24),
                                                  Text(
                                                    'Subscription Management',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'You can upgrade, downgrade, or cancel your active subscription anytime. Downgrades take effect at the end of the current billing cycle. Refunds are managed directly by your respective App Store.',
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
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
                              child: const Text(
                                'Terms & Privacy',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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
