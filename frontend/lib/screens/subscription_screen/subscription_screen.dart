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
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88, initialPage: 0);
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

  // Widget _buildFeatureHighlights() {
  //   final features = [
  //     {
  //       'icon': Icons.favorite_rounded,
  //       'title': 'See Who Likes You',
  //       'desc': 'View list of profiles who liked you',
  //     },
  //     {
  //       'icon': Icons.chat_bubble_rounded,
  //       'title': 'Unlimited Chatting',
  //       'desc': 'Send direct texts without any daily cap',
  //     },
  //     {
  //       'icon': Icons.public_rounded,
  //       'title': 'Global Search',
  //       'desc': 'Discover matches across regions & cities',
  //     },
  //   ];

  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 24),
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: AppColors.surface,
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(color: AppColors.borderColor, width: 1.2),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'Premium Benefits Included',
  //           style: TextStyle(
  //             fontSize: 13,
  //             fontWeight: FontWeight.bold,
  //             color: AppColors.textPrimary,
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         ...features.map(
  //           (f) => Padding(
  //             padding: const EdgeInsets.only(bottom: 10),
  //             child: Row(
  //               children: [
  //                 Container(
  //                   padding: const EdgeInsets.all(8),
  //                   decoration: BoxDecoration(
  //                     color: AppColors.primary.withValues(alpha: 0.1),
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                   child: Icon(
  //                     f['icon'] as IconData,
  //                     size: 16,
  //                     color: AppColors.primary,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         f['title'] as String,
  //                         style: const TextStyle(
  //                           fontSize: 12,
  //                           fontWeight: FontWeight.bold,
  //                           color: AppColors.textPrimary,
  //                         ),
  //                       ),
  //                       Text(
  //                         f['desc'] as String,
  //                         style: const TextStyle(
  //                           fontSize: 10,
  //                           color: AppColors.textSecondary,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildActivePlanBanner(model.SubscriptionPlan plan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success, width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT ACTIVE PLAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choose Your Plan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
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

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                              'Unlock Premium Features',
                              style: const TextStyle(
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
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 20),
                        if (currentSub?.isActive ?? false)
                          _buildActivePlanBanner(currentSub!),
                        // _buildFeatureHighlights().animate().fadeIn(
                        //   delay: 300.ms,
                        // ),
                      ],
                    ),
                  ),

                  // Horizontal Carousel of Plans
                  SizedBox(
                    height: 385,
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
                            currentSub != null && currentSub.id == plan.id;
                        final isSelectedPage = index == _currentPage;

                        return AnimatedScale(
                          scale: isSelectedPage ? 1.0 : 0.94,
                          duration: const Duration(milliseconds: 250),
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

                  // Carousel Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      plans.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(
    model.SubscriptionPlan plan,
    bool isCurrentPlan,
    bool isLoading,
    bool isSelectedPage,
  ) {
    final isPopular = plan.isMostPopular;

    // Define color mappings for active/popular states
    final hasDarkBg = isPopular && !isCurrentPlan;
    final cardBgColor = hasDarkBg ? null : AppColors.surface;
    final cardGradient = hasDarkBg
        ? const LinearGradient(
            colors: [Color(0xFFFF3F3F), Color(0xFFFF6B6B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final titleColor = hasDarkBg ? Colors.white : AppColors.textPrimary;
    final subtitleColor = hasDarkBg
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.textSecondary;
    final dividerColor = hasDarkBg
        ? Colors.white.withValues(alpha: 0.3)
        : AppColors.divider;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrentPlan
              ? AppColors.black
              : isPopular
              ? AppColors.primary
              : AppColors.borderColor,
          width: isPopular || isCurrentPlan ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
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
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 10, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                if (plan.price > 0)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.displayPrice,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                        child: Text(
                          '/ ${plan.rcDurationTitle ?? '${plan.durationDays} days'}',
                          style: TextStyle(fontSize: 12, color: subtitleColor),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Get Started Free',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: hasDarkBg ? Colors.white : AppColors.primary,
                    ),
                  ),
                const SizedBox(height: 12),
                Divider(color: dividerColor, height: 1),
                const SizedBox(height: 12),
                // Feature List
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: plan.featureDescriptions
                        .map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: hasDarkBg
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: titleColor,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  onPressed: isCurrentPlan || isLoading
                      ? () {}
                      : () => _handleSubscribe(plan),
                  text: isCurrentPlan
                      ? 'Current Plan'
                      : isLoading
                      ? 'Processing...'
                      : 'Select ${plan.name}',
                  type: isCurrentPlan
                      ? CustomButtonType.secondary
                      : isPopular
                      ? CustomButtonType.primary
                      : CustomButtonType.outline,
                  backgroundColor: isCurrentPlan
                      ? AppColors.divider
                      : isPopular
                      ? (hasDarkBg ? Colors.white : AppColors.primary)
                      : AppColors.primary,
                  textColor: isCurrentPlan
                      ? AppColors.textSecondary
                      : isPopular
                      ? (hasDarkBg ? AppColors.primary : Colors.white)
                      : AppColors.primary,
                  width: double.infinity,
                  borderRadius: 14,
                  height: 46,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
