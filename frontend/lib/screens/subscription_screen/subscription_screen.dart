import 'package:flutter/material.dart';
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

  _PlanVisuals _getPlanVisuals(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('gold')) {
      return _PlanVisuals(
        themeColor: const Color(0xFFF1A80A),
        borderColor: const Color(0xFFFFD54F),
        bgColor: const Color(0xFFFFFDF7),
        coupleAsset: 'assets/images/landing_couple_1.png',
        shortcutIcons: [
          Icons.chat_bubble_outline_rounded,
          Icons.phone_outlined,
          Icons.videocam_outlined,
          Icons.shield_outlined,
        ],
        isPopular: false,
      );
    } else if (lower.contains('platinum')) {
      return _PlanVisuals(
        themeColor: const Color(0xFF1E88E5),
        borderColor: const Color(0xFF90CAF9),
        bgColor: const Color(0xFFF4FAFF),
        coupleAsset: 'assets/images/landing_couple_3.png',
        shortcutIcons: [
          Icons.chat_bubble_outline_rounded,
          Icons.phone_outlined,
          Icons.videocam_outlined,
          Icons.visibility_outlined,
          Icons.shield_outlined,
        ],
        isPopular: false,
      );
    } else {
      return _PlanVisuals(
        themeColor: const Color(0xFFFF2D55),
        borderColor: const Color(0xFFFF8A9F),
        bgColor: const Color(0xFFFFF5F6),
        coupleAsset: 'assets/images/landing_couple_2.png',
        shortcutIcons: [
          Icons.chat_bubble_outline_rounded,
          Icons.phone_outlined,
          Icons.videocam_outlined,
          Icons.visibility_outlined,
          Icons.shield_outlined,
        ],
        isPopular: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choose Your Plan',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: Color(0xFFFF2D55),
              size: 24,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
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

          // Safely bound current page in case plans list changed
          if (_currentPage >= plans.length && plans.isNotEmpty) {
            _currentPage = plans.length - 1;
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                const Text(
                  'Unlock more ways to connect',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Horizontal Carousel of Plans
                if (plans.isNotEmpty) ...[
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
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
                          scale: isSelectedPage ? 1.0 : 0.92,
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
                  const SizedBox(height: 20),

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
                              ? const Color(0xFFFF2D55)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Dynamic Select Button below PageView
                  Builder(
                    builder: (context) {
                      final plan = plans[_currentPage];
                      final isCurrentPlan =
                          currentSub != null && currentSub.id == plan.id;

                      String buttonText = 'Choose ${plan.name}';
                      if (isCurrentPlan) {
                        buttonText = 'Current Active Plan';
                      } else if (provider.isLoading) {
                        buttonText = 'Processing...';
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFE3F6C), Color(0xFFFF527B)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFE3F6C,
                                ).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isCurrentPlan || provider.isLoading
                                ? null
                                : () => _handleSubscribe(plan),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Text(
                              buttonText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        'No subscription plans available.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
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
    final visuals = _getPlanVisuals(plan.name);

    final features = plan.featureDescriptions.isNotEmpty
        ? plan.featureDescriptions
        : [
            'Message Anyone',
            'Interest List',
            'Audio Call Access',
            'Photo Privacy',
            'See Who Liked You',
          ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: visuals.borderColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: visuals.themeColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (visuals.isPopular)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: visuals.themeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: visuals.themeColor,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: visuals.themeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.price > 0 ? plan.displayPrice : 'Free',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${plan.durationDays} days',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: visuals.themeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(visuals.coupleAsset, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Column(
                    children: features.take(5).map((feature) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: visuals.themeColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: visuals.shortcutIcons.map((icon) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: visuals.themeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: visuals.themeColor),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanVisuals {
  final Color themeColor;
  final Color borderColor;
  final Color bgColor;
  final String coupleAsset;
  final List<IconData> shortcutIcons;
  final bool isPopular;

  _PlanVisuals({
    required this.themeColor,
    required this.borderColor,
    required this.bgColor,
    required this.coupleAsset,
    required this.shortcutIcons,
    required this.isPopular,
  });
}
