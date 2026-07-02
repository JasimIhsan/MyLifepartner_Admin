import 'package:flutter/material.dart';
import 'package:mylifepartner/config/env.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/subscription_plan.dart' as model;
import 'package:mylifepartner/providers/subscription_provider.dart';
import 'package:mylifepartner/screens/subscription_screen/connection_illustration.dart';
import 'package:mylifepartner/screens/subscription_screen/subscription_background_painter.dart';
import 'package:mylifepartner/screens/subscription_screen/subscription_error_widget.dart';
import 'package:mylifepartner/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
    _initSubscriptions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  _PlanVisuals _getPlanVisuals(model.SubscriptionPlan plan) {
    if (plan.price == 0) {
      return _PlanVisuals(
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
      return _PlanVisuals(
        themeColor: AppColors.primary,
        borderColor: AppColors.primaryLight,
        bgColor: const Color(0xFFF8FAFC),
        gradientColors: const [AppColors.primaryLight, AppColors.primary],
        isPopular: true,
        badgeText: 'Most Popular',
      );
    } else if (nameLower.contains('yearly') || nameLower.contains('annual')) {
      return _PlanVisuals(
        themeColor: AppColors.primary,
        borderColor: AppColors.primaryLight,
        bgColor: const Color(0xFFF8FAFC),
        gradientColors: const [AppColors.primaryLight, AppColors.primaryDark],
        isPopular: false,
        badgeText: '40% OFF',
      );
    } else {
      return _PlanVisuals(
        themeColor: AppColors.primary,
        borderColor: AppColors.borderColor,
        bgColor: const Color(0xFFF8FAFC),
        gradientColors: const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
        isPopular: false,
        badgeText: null,
      );
    }
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
              onRetry: _initSubscriptions,
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
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),

                              // Intro Banner Section
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Better matches,\nmeaningful connections',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.textPrimary,
                                              height: 1.25,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Premium perks to help you find your perfect life partner.',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      flex: 2,
                                      child: ConnectionIllustration(),
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

                                      return AnimatedScale(
                                        scale: isSelectedPage ? 1.0 : 0.94,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        child: _buildPlanCard(
                                          plan,
                                          isCurrentPlan,
                                          provider.isLoading,
                                          isSelectedPage,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Indicators
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(plans.length, (
                                    index,
                                  ) {
                                    final isSelected = _currentPage == index;
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width: isSelected ? 24 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    );
                                  }),
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
                                          _buildCancelConfirmationSheet(),
                                    );

                                if (confirm == true) {
                                  // Locate the FREE plan identifier/id in plans list
                                  final freePlan = provider.plans.firstWhere(
                                    (p) => p.price == 0,
                                  );
                                  _handleSubscribe(freePlan);
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
                                                        Navigator.pop(context),
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
            onPressed: () => Navigator.pop(context),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Skip',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    model.SubscriptionPlan plan,
    bool isCurrentPlan,
    bool isLoading,
    bool isSelectedPage,
  ) {
    final visuals = _getPlanVisuals(plan);

    // Default clean features for the mockup description UI
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

    String durationText = 'Forever';
    if (plan.price > 0) {
      if (plan.durationDays == 30) {
        durationText = 'per month';
      } else if (plan.durationDays == 365) {
        durationText = 'per year';
      } else {
        durationText = 'for ${plan.durationDays} days';
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Card
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelectedPage
                  ? visuals.borderColor
                  : AppColors.borderColor,
              width: isSelectedPage ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelectedPage
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.03),
                blurRadius: isSelectedPage ? 20 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Plan Name
              Text(
                plan.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Price Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: [
                  Text(
                    plan.price > 0 ? plan.displayPrice : '₹0',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                durationText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),

              // Features List
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayFeatures.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              displayFeatures[index],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Dynamic selection button
              const SizedBox(height: 16),
              if (isCurrentPlan)
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${plan.name} Plan Details',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        'Price: ${plan.displayPrice}',
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
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
                    },
                    child: const Text(
                      'Details',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else if (visuals.isPopular)
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: visuals.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _handleSubscribe(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Choose',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _handleSubscribe(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Choose',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Optional badge overlay (e.g. Most Popular, 40% OFF)
        if (visuals.badgeText != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: visuals.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  visuals.badgeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanVisuals {
  final Color themeColor;
  final Color borderColor;
  final Color bgColor;
  final List<Color> gradientColors;
  final bool isPopular;
  final String? badgeText;

  _PlanVisuals({
    required this.themeColor,
    required this.borderColor,
    required this.bgColor,
    required this.gradientColors,
    required this.isPopular,
    required this.badgeText,
  });
}
