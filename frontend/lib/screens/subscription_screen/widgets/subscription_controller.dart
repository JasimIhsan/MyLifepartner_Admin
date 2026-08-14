import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/subscription_plan.dart' as model;
import 'package:life_partner_again/providers/subscription_provider.dart';
import 'package:life_partner_again/widgets/bottomsheet/subscription/dynamic_loading_ui.dart';
import 'package:life_partner_again/widgets/bottomsheet/subscription/subscription_failure_ui.dart';
import 'package:life_partner_again/widgets/bottomsheet/subscription/subscription_success_ui.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_partner_again/models/auth_response.dart' as auth_model;
import 'package:life_partner_again/services/user_repository.dart';

class PlanVisuals {
  final Color themeColor;
  final Color borderColor;
  final Color bgColor;
  final List<Color> gradientColors;
  final bool isPopular;
  final String? badgeText;

  PlanVisuals({
    required this.themeColor,
    required this.borderColor,
    required this.bgColor,
    required this.gradientColors,
    required this.isPopular,
    required this.badgeText,
  });
}

mixin SubscriptionControllerState<T extends StatefulWidget> on State<T> {
  bool _awaitingStoreReturn = false;
  late final _SubscriptionLifecycleObserver _lifecycleObserver;

  auth_model.User? user;
  bool isUserLoading = true;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = _SubscriptionLifecycleObserver(
      onResumed: () {
        if (_awaitingStoreReturn) {
          _awaitingStoreReturn = false;
          debugPrint(
            "📱 App resumed after store redirect. Triggering subscription refresh retry...",
          );
          if (mounted) {
            context.read<SubscriptionProvider>().refreshWithRetry();
          }
        }
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  void initSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    debugPrint("UserId from prefs: $userId");
    if (userId == 0) {
      debugPrint("Invalid userId");
      return;
    }

    try {
      final fetchedUser = await UserRepository().getUser();
      if (mounted) {
        setState(() {
          user = fetchedUser;
          isUserLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user in SubscriptionControllerState: $e");
      if (mounted) {
        setState(() {
          isUserLoading = false;
        });
      }
    }

    if (!mounted) return;

    context.read<SubscriptionProvider>().loadSubscriptions(userId.toString());
  }

  Future<void> handleCancelSubscription() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => buildCancelConfirmationSheet(),
    );

    if (confirm == true) {
      if (kDebugMode) {
        if (mounted) {
          final isCompleted = ValueNotifier(false);
          final dialogFuture = showDynamicLoadingUI(context, isCompleted);

          await context.read<SubscriptionProvider>().cancelSubscriptionDebug();

          isCompleted.value = true;
          await dialogFuture;

          if (mounted) {
            initSubscriptions();
          }
        }
      } else {
        _awaitingStoreReturn = true;
        if (mounted) {
          await context
              .read<SubscriptionProvider>()
              .openStoreSubscriptionManagement();
        }
      }
    }
  }

  Future<void> handleRestorePurchases() async {
    final provider = context.read<SubscriptionProvider>();
    final ValueNotifier<bool> isCompleted = ValueNotifier(false);
    final dialogFuture = showDynamicLoadingUI(context, isCompleted);

    final success = await provider.restorePurchases();

    if (!mounted) return;

    isCompleted.value = true;
    await dialogFuture;

    if (!mounted) return;

    if (success) {
      final restoredPlan = provider.currentSubscription;
      if (restoredPlan != null) {
        await showSubscriptionSuccessUI(context, restoredPlan);
      }

      if (mounted) {
        initSubscriptions();
      }
    } else {
      await showSubscriptionFailureUI(context, provider.error);
    }
  }

  void handleSubscribe(model.SubscriptionPlan plan) async {
    final provider = context.read<SubscriptionProvider>();

    if (user?.isFoundingMember == true) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 48),
              const SizedBox(height: 16),
              Text(
                'Founding Member',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You are a founding member and already have complete free premium access to the application. Thank you for your support!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color ??
                      AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  onPressed: () => context.pop(),
                  text: 'Got it',
                  type: CustomButtonType.primary,
                  backgroundColor: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  height: 52,
                  borderRadius: 16,
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    if (plan.price == 0 &&
        provider.currentSubscription != null &&
        provider.currentSubscription!.price > 0) {
      final mySub = provider.mySubscription;
      if (mySub != null &&
          (!mySub.willRenew ||
              mySub.isCancelledButActive ||
              mySub.isDowngradeScheduled ||
              mySub.isCancelled ||
              mySub.isInGracePeriod ||
              mySub.isPaymentFailed)) {
        _awaitingStoreReturn = true;
        if (mounted) {
          await provider.openStoreSubscriptionManagement();
        }
        return;
      }
      await handleCancelSubscription();
      return;
    }

    bool dialogShown = false;
    final ValueNotifier<bool> isCompleted = ValueNotifier(false);
    Future<void>? dialogFuture;

    final success = await provider.subscribeToPlan(
      plan.identifier ?? plan.id.toString(),
      onPurchaseCompleted: () {
        dialogShown = true;
        dialogFuture = showDynamicLoadingUI(context, isCompleted);
      },
    );

    if (!mounted) return;

    if (dialogShown) {
      isCompleted.value = true;
      if (dialogFuture != null) {
        await dialogFuture;
      }
    }

    if (!mounted) return;

    if (success) {
      await showSubscriptionSuccessUI(context, plan);

      if (mounted) {
        initSubscriptions();
      }
    } else {
      await showSubscriptionFailureUI(context, provider.error);
    }
  }

  Widget buildCancelConfirmationSheet() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            'Cancel Subscription?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ??
                  AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'To cancel your subscription, you will be directed to your ${(defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) ? "Apple App Store" : "Google Play"} subscription settings. Your premium features will remain active until the end of your current billing period.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  onPressed: () => context.pop(true),
                  text: 'Yes, Cancel',
                  type: CustomButtonType.outline,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  textColor:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      AppColors.textPrimary,
                  height: 52,
                  borderRadius: 16,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  onPressed: () => context.pop(false),
                  text: 'Keep Plan',
                  type: CustomButtonType.primary,
                  backgroundColor: Theme.of(context).primaryColor,
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

  PlanVisuals getPlanVisuals(model.SubscriptionPlan plan) {
    if (plan.price == 0) {
      return PlanVisuals(
        themeColor:
            Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textLight,
        borderColor: Theme.of(context).dividerColor,
        bgColor: Theme.of(context).scaffoldBackgroundColor,
        gradientColors: const [Color(0xFF94A3B8), Color(0xFF64748B)],
        isPopular: false,
        badgeText: null,
      );
    }

    final nameLower = plan.name.toLowerCase();
    if (plan.isMostPopular) {
      return PlanVisuals(
        themeColor: Theme.of(context).primaryColor,
        borderColor: Theme.of(context).primaryColorLight,
        bgColor: Color(0xFFF8FAFC),
        gradientColors: [
          Theme.of(context).primaryColorLight,
          Theme.of(context).primaryColor,
        ],
        isPopular: true,
        badgeText: 'Most Popular',
      );
    } else if (nameLower.contains('yearly') || nameLower.contains('annual')) {
      return PlanVisuals(
        themeColor: Theme.of(context).primaryColor,
        borderColor: Theme.of(context).primaryColorLight,
        bgColor: Color(0xFFF8FAFC),
        gradientColors: [
          Theme.of(context).primaryColorLight,
          Theme.of(context).primaryColorDark,
        ],
        isPopular: false,
        badgeText: '40% OFF',
      );
    } else {
      return PlanVisuals(
        themeColor: Theme.of(context).primaryColor,
        borderColor: Theme.of(context).dividerColor,
        bgColor: const Color(0xFFF8FAFC),
        gradientColors: const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
        isPopular: false,
        badgeText: null,
      );
    }
  }
}

class _SubscriptionLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback onResumed;

  _SubscriptionLifecycleObserver({required this.onResumed});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}
