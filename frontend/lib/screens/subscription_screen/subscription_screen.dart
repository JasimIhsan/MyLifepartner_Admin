import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../shared/widgets/custom_button.dart';

class SubscriptionPlan {
  final String title;
  final String price;
  final List<String> features;
  final bool isPopular;

  SubscriptionPlan({
    required this.title,
    required this.price,
    required this.features,
    this.isPopular = false,
  });
}

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static final List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      title: 'Free',
      price: '\$0',
      features: [
        'Basic profile visibility',
        'Send 10 likes per day',
        'Limited matches',
        'See only mutual interests',
      ],
    ),
    SubscriptionPlan(
      title: 'Premium',
      price: '\$19.99',
      features: [
        'Unlimited likes',
        'See who liked you',
        'Rewind previous swipes',
        '5 Super Likes per day',
        'No ads',
      ],
      isPopular: true,
    ),
    SubscriptionPlan(
      title: 'Diamond',
      price: '\$49.99',
      features: [
        'Everything in Premium',
        'Priority likes',
        'Message before matching',
        'See Profile Boosts',
        'Advanced matching filters',
      ],
    ),
  ];

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
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlock Premium Features',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text(
                'Choose a plan that fits your needs and start your journey towards finding your life partner.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 32),
              ...plans.asMap().entries.map((entry) {
                final index = entry.key;
                final plan = entry.value;
                return _buildPlanCard(plan)
                    .animate()
                    .fadeIn(delay: (400 + (index * 100)).ms, duration: 500.ms)
                    .slideX(begin: 0.1, end: 0);
              }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: plan.isPopular ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: plan.isPopular ? AppColors.primary : AppColors.borderColor,
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
          if (plan.isPopular)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.onPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'MOST POPULAR',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: plan.isPopular ? AppColors.onPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.price,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: plan.isPopular ? AppColors.onPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5, left: 4),
                      child: Text(
                        '/month',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: plan.isPopular ? AppColors.onPrimary.withValues(alpha: 0.7) : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 24),
                ...plan.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: plan.isPopular ? AppColors.onPrimary : AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: plan.isPopular ? AppColors.onPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                CustomButton(
                  onPressed: () {},
                  text: plan.title == 'Free' ? 'Current Plan' : 'Select ${plan.title}',
                  type: plan.isPopular ? CustomButtonType.primary : CustomButtonType.outline,
                  backgroundColor: plan.isPopular ? AppColors.onPrimary : AppColors.primary,
                  textColor: plan.isPopular ? AppColors.primary : AppColors.primary,
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
