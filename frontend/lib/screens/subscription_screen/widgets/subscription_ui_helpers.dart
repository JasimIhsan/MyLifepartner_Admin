import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/subscription_plan.dart' as model;
import 'package:life_partner_again/screens/subscription_screen/widgets/subscription_controller.dart';

class PlanCardWidget extends StatelessWidget {
  final model.SubscriptionPlan plan;
  final bool isCurrentPlan;
  final bool isLoading;
  final bool isSelectedPage;
  final bool willRenew;
  final bool hasBillingIssue;
  final bool isInGracePeriod;
  final bool isCancelledButActive;
  final bool isDowngradeScheduled;
  final bool isCancelled;
  final PlanVisuals visuals;
  final VoidCallback onSubscribe;
  final VoidCallback onInfoTap;

  const PlanCardWidget({
    super.key,
    required this.plan,
    required this.isCurrentPlan,
    required this.isLoading,
    required this.isSelectedPage,
    required this.willRenew,
    this.hasBillingIssue = false,
    this.isInGracePeriod = false,
    this.isCancelledButActive = false,
    this.isDowngradeScheduled = false,
    this.isCancelled = false,
    required this.visuals,
    required this.onSubscribe,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
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
        durationText = 'for \${plan.durationDays} days';
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
              color: isCurrentPlan
                  ? (hasBillingIssue
                        ? Colors.red
                        : (isInGracePeriod
                              ? Colors.orange
                              : (isDowngradeScheduled || isCancelled
                                    ? Colors.grey
                                    : Theme.of(context).primaryColor)))
                  : (isSelectedPage
                        ? visuals.borderColor
                        : Theme.of(context).dividerColor),
              width: (isCurrentPlan || isSelectedPage) ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelectedPage
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.12)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.03),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
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
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                durationText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              if (isCurrentPlan &&
                  (hasBillingIssue ||
                      isInGracePeriod ||
                      isDowngradeScheduled ||
                      isCancelled)) ...[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: hasBillingIssue
                          ? const Color(0xFFFEF2F2)
                          : (isInGracePeriod
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasBillingIssue
                            ? const Color(0xFFFCA5A5)
                            : (isInGracePeriod
                                  ? const Color(0xFFFCD34D)
                                  : const Color(0xFFCBD5E1)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasBillingIssue
                              ? Icons.error_outline
                              : (isInGracePeriod
                                    ? Icons.warning_amber_rounded
                                    : Icons.info_outline_rounded),
                          size: 14,
                          color: hasBillingIssue
                              ? const Color(0xFFDC2626)
                              : (isInGracePeriod
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF475569)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasBillingIssue
                              ? 'Payment Failed'
                              : (isInGracePeriod
                                    ? 'Grace Period'
                                    : (isDowngradeScheduled
                                          ? 'Downgrades soon'
                                          : 'Plan Cancelled')),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: hasBillingIssue
                                ? const Color(0xFFDC2626)
                                : (isInGracePeriod
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              displayFeatures[index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
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
                if (plan.price == 0)
                  Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'Active Plan',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  )
                else if (hasBillingIssue)
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: TextButton(
                      onPressed: () => onSubscribe(),
                      child: const Text(
                        'Fix Payment Issue',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else if (isInGracePeriod)
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: TextButton(
                      onPressed: () => onSubscribe(),
                      child: const Text(
                        'Renew Now (Grace Period)',
                        style: TextStyle(
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else if (isDowngradeScheduled ||
                    isCancelledButActive ||
                    isCancelled ||
                    !willRenew)
                  const SizedBox.shrink()
                else
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => onSubscribe(),
                      child: Text(
                        'Cancel Subscription',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
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
                    gradient: plan.price == 0
                        ? null
                        : LinearGradient(
                            colors: visuals.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: plan.price == 0 ? const Color(0xFFF1F5F9) : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: plan.price == 0
                        ? null
                        : [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: (isLoading || plan.price == 0)
                        ? null
                        : onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      plan.price == 0 ? 'Free Plan' : 'Subscribe',
                      style: TextStyle(
                        color: plan.price == 0
                            ? Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary
                            : Colors.white,
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
                    onPressed: (isLoading || plan.price == 0)
                        ? null
                        : onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      plan.price == 0 ? 'Free Plan' : 'Subscribe',
                      style: TextStyle(
                        color: plan.price == 0
                            ? Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary
                            : Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Info button in the top right corner of the current plan card (only if not free plan)
        if (isCurrentPlan && plan.price > 0)
          Positioned(
            top: 24,
            right: 24,
            child: GestureDetector(
              onTap: onInfoTap,
              child: const Icon(
                Icons.info_outline_rounded,
                color: Colors.grey,
                size: 22,
              ),
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
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
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