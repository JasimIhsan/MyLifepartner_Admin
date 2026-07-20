import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/providers/subscription_provider.dart';
import 'package:life_partner_again/screens/subscription_screen/subscription_background_painter.dart';
import 'package:life_partner_again/screens/subscription_screen/subscription_error_widget.dart';
import 'package:life_partner_again/screens/subscription_screen/widgets/subscription_controller.dart';
import 'package:life_partner_again/screens/subscription_screen/widgets/subscription_ui_helpers.dart';
import 'package:life_partner_again/models/subscription_plan.dart' as model;
import 'package:provider/provider.dart';

class MobileSubscriptionScreen extends StatefulWidget {
  const MobileSubscriptionScreen({super.key});

  @override
  State<MobileSubscriptionScreen> createState() =>
      _MobileSubscriptionScreenState();
}

class _MobileSubscriptionScreenState extends State<MobileSubscriptionScreen>
    with SubscriptionControllerState<MobileSubscriptionScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
    initSubscriptions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          const Text(
            'Choose Your Plan',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
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

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final provider = context.read<SubscriptionProvider>();
        return Padding(
          padding: const EdgeInsets.all(24.0),
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
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        feat,
                        style: const TextStyle(
                          fontSize: 13,
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
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(color: AppColors.primary),
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

          if (_currentPage >= plans.length && plans.isNotEmpty) {
            _currentPage = plans.length - 1;
          }

          return Stack(
            children: [
              // Full screen waves background design
              const SubscriptionBackground(),

              // Beautiful top gradient background glow matching the design
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pinned-like custom app bar integrated directly within background design
                      _buildCustomAppBar(context),

                      // Scrollable content area
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 12),

                                      // Intro Banner Section (Variant 3)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24.0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // Circular Logo with Glowing Ring & Floating Hearts
                                            SizedBox(
                                              width: 150,
                                              height: 150,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                clipBehavior: Clip.none,
                                                children: [
                                                  // Inner circle with logo
                                                  Container(
                                                    width: 110,
                                                    height: 110,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: AppColors.primary
                                                            .withValues(
                                                              alpha: 0.08,
                                                            ),
                                                        width: 6,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: AppColors
                                                              .primary
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                          blurRadius: 20,
                                                          spreadRadius: 2,
                                                          offset: const Offset(
                                                            0,
                                                            8,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                          18,
                                                        ),
                                                    child: Image.asset(
                                                      'assets/icons/app_logo.png',
                                                      fit: BoxFit.contain,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => const Icon(
                                                            Icons.favorite,
                                                            color: AppColors
                                                                .primary,
                                                            size: 32,
                                                          ),
                                                    ),
                                                  ),
                                                  // Left Floating Heart
                                                  Positioned(
                                                    left: 2,
                                                    top: 40,
                                                    child: Icon(
                                                      Icons.favorite_rounded,
                                                      color: Colors.redAccent
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                      size: 18,
                                                    ),
                                                  ),
                                                  // Right Floating Heart
                                                  Positioned(
                                                    right: 6,
                                                    top: 50,
                                                    child: Icon(
                                                      Icons.favorite_rounded,
                                                      color: Colors.redAccent
                                                          .withValues(
                                                            alpha: 0.4,
                                                          ),
                                                      size: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Unlock Premium Perks',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.textPrimary,
                                                height: 1.25,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24.0,
                                              ),
                                              child: Text(
                                                'Premium perks to help you find your perfect life partner.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      // Features Horizontal List
                                      // _buildFeatureIconsRow(),
                                      const SizedBox(height: 28),

                                      if (plans.isNotEmpty) ...[
                                        // PageView for plan cards
                                        SizedBox(
                                          height: 410,
                                          child: PageView.builder(
                                            controller: _pageController,
                                            itemCount: plans.length,
                                            onPageChanged: (page) {
                                              setState(() {
                                                _currentPage = page;
                                              });
                                            },
                                            itemBuilder: (context, index) {
                                              final plan = plans[index];
                                              final isCurrentPlan =
                                                  currentSub != null &&
                                                  currentSub.id == plan.id;
                                              final isSelectedPage =
                                                  index == _currentPage;

                                              final visuals = getPlanVisuals(
                                                plan,
                                              );

                                              return AnimatedScale(
                                                scale: isSelectedPage
                                                    ? 1.0
                                                    : 0.94,
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                curve: Curves.easeOutCubic,
                                                child: PlanCardWidget(
                                                  plan: plan,
                                                  isCurrentPlan: isCurrentPlan,
                                                  isLoading: provider.isLoading,
                                                  isSelectedPage:
                                                      isSelectedPage,
                                                  willRenew:
                                                      provider
                                                          .mySubscription
                                                          ?.willRenew ??
                                                      true,
                                                  visuals: visuals,
                                                  onSubscribe: () {
                                                    if (isCurrentPlan &&
                                                        plan.price > 0) {
                                                      handleSubscribe(
                                                        provider.plans
                                                            .firstWhere(
                                                              (p) =>
                                                                  p.price == 0,
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
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Indicators
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(
                                            plans.length,
                                            (index) {
                                              final isSelected =
                                                  _currentPage == index;
                                              return AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 250,
                                                ),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                width: isSelected ? 24 : 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : const Color(0xFFE2E8F0),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ] else ...[
                                        const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(40.0),
                                            child: Text(
                                              'No subscription plans available.',
                                              style: TextStyle(
                                                color: AppColors.textLight,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Pinned Bottom Actions Row at the bottom of the viewport
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () async {
                                final provider = context
                                    .read<SubscriptionProvider>();
                                if (provider.mySubscription != null &&
                                    !provider.mySubscription!.willRenew) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Your plan is already cancelled and will downgrade on expiration.',
                                      ),
                                      backgroundColor: Colors.black,
                                    ),
                                  );
                                  return;
                                }

                                if (provider.currentSubscription == null ||
                                    provider.currentSubscription!.price == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'You are already on the Free plan.',
                                      ),
                                      backgroundColor: Colors.black,
                                    ),
                                  );
                                  return;
                                }

                                final confirm =
                                    await showModalBottomSheet<bool>(
                                      context: context,
                                      backgroundColor: AppColors.surface,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24),
                                        ),
                                      ),
                                      builder: (context) =>
                                          buildCancelConfirmationSheet(),
                                    );

                                if (confirm == true) {
                                  // Locate the FREE plan identifier/id in plans list
                                  final freePlan = provider.plans.firstWhere(
                                    (p) => p.price == 0,
                                  );
                                  handleSubscribe(freePlan);
                                }
                              },
                              child: const Text(
                                'Restore Subscription',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: AppColors.surface,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  builder: (context) {
                                    return DraggableScrollableSheet(
                                      initialChildSize: 0.6,
                                      minChildSize: 0.4,
                                      maxChildSize: 0.9,
                                      expand: false,
                                      builder: (context, scrollController) {
                                        return Padding(
                                          padding: const EdgeInsets.all(24.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Terms & Privacy Policy',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.close_rounded,
                                                    ),
                                                    onPressed: () =>
                                                        context.pop(),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Expanded(
                                                child: ListView(
                                                  controller: scrollController,
                                                  children: const [
                                                    Text(
                                                      'Terms of Service',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                    SizedBox(height: 6),
                                                    Text(
                                                      'Welcome to Life Partner Again. By subscribing to our premium plans, you agree to comply with and be bound by our general terms of service. Subscriptions automatically renew at the end of the billing period unless cancelled at least 24 hours prior to renewal.',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: AppColors
                                                            .textSecondary,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                    SizedBox(height: 16),
                                                    Text(
                                                      'Privacy Policy',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                    SizedBox(height: 6),
                                                    Text(
                                                      'We take your privacy seriously. We store your account details securely and process payments through safe systems (RevenueCat, App Store, Google Play). Your profile image and educational history are used solely to improve connections and match preferences. You can manage photo blurring and profile privacy settings directly from your settings panel.',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: AppColors
                                                            .textSecondary,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                    SizedBox(height: 16),
                                                    Text(
                                                      'Subscription Management',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                    SizedBox(height: 6),
                                                    Text(
                                                      'You can upgrade, downgrade, or cancel your active subscription anytime. Downgrades take effect at the end of the current billing cycle. Refunds are managed directly by your respective App Store.',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: AppColors
                                                            .textSecondary,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                              child: const Text(
                                'Terms & Privacy',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
