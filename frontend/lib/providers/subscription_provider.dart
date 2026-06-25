import 'package:flutter/material.dart';
import 'package:mylifepartner/config/env.dart';
import 'package:mylifepartner/models/subscription_plan.dart';
import 'package:mylifepartner/services/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  List<SubscriptionPlan> plans = [];
  SubscriptionPlan? currentSubscription;

  List<Package> _rcPackages = [];

  bool _isPurchasing = false;
  bool _isInitialized = false;
  final SubscriptionService _subscriptionService = SubscriptionService();

  /// =========================
  /// INIT (call once)
  /// =========================
  Future<void> init(String userId) async {
    if (_isInitialized) return;

    try {
      await Purchases.configure(PurchasesConfiguration(Env.revenueCatApiKey));

      await Purchases.logIn(userId);

      Purchases.addCustomerInfoUpdateListener((info) {
        _handleCustomerInfoUpdate(info);
      });

      _isInitialized = true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// =========================
  /// MAIN ENTRY (replace fetchPlans)
  /// =========================
  Future<void> loadSubscriptions(String userId) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      await init(userId);

      final results = await Future.wait([
        _fetchBackendPlans(),
        _fetchRevenueCatPlans(),
        _fetchCustomerInfo(),
      ]);

      final backendPlans = results[0] as List<SubscriptionPlan>;
      final rcPackages = results[1] as List<Package>;
      final customerInfo = results[2] as CustomerInfo;

      _rcPackages = rcPackages;

      _mergePlans(backendPlans: backendPlans, rcPackages: rcPackages);

      _setCurrentSubscription(customerInfo);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// =========================
  /// FETCH: Backend
  /// =========================
  Future<List<SubscriptionPlan>> _fetchBackendPlans() async {
    try {
      debugPrint("🌐 Fetching backend plans...");

      final plans = await _subscriptionService.getPlans();

      debugPrint("✅ Backend plans count: ${plans.length}");

      return plans; // ✅ already parsed
    } catch (e, stack) {
      debugPrint("❌ Error fetching backend plans: $e");
      debugPrint("$stack");
      return [];
    }
  }

  /// =========================
  /// FETCH: RevenueCat
  /// =========================
  Future<List<Package>> _fetchRevenueCatPlans() async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;

    debugPrint("🔥 Offerings object: $offerings");
    debugPrint("🔥 Current offering: ${offerings.current}");
    debugPrint("🔥 All offerings: ${offerings.all}");

    if (current == null) {
      throw Exception("No offerings configured in RevenueCat");
    }

    return current.availablePackages;
  }

  /// =========================
  /// FETCH: Customer Info
  /// =========================
  Future<CustomerInfo> _fetchCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  /// =========================
  /// MERGE LOGIC
  /// =========================
  void _mergePlans({
    required List<SubscriptionPlan> backendPlans,
    required List<Package> rcPackages,
  }) {
    if (backendPlans.isEmpty) {
      error = "No plans available right now. Please try again later.";
      plans = [];
      return;
    }

    if (rcPackages.isEmpty) {
      error = "Subscription service is currently unavailable.";
      plans = [];
      return;
    }

    final List<SubscriptionPlan> merged = [];

    for (final plan in backendPlans) {
      final productId = plan.id.toString();

      final match = rcPackages.where(
        (pkg) => pkg.storeProduct.identifier == productId,
      );

      if (match.isEmpty) {
        debugPrint(
          "❌ CRITICAL: No match for backend plan ${plan.id} with productId=$productId",
        );

        // 🔥 HARD FAIL — stop everything
        error =
            "We are facing issues loading subscription plans. Please try again later.";

        plans = [];
        notifyListeners();
        return;
      }

      final product = match.first.storeProduct;

      merged.add(
        plan.copyWith(
          rcDisplayPrice: product.priceString,
          rcPrice: product.price,
        ),
      );
    }

    plans = merged;
  }

  /// =========================
  /// CURRENT SUBSCRIPTION
  /// =========================
  void _setCurrentSubscription(CustomerInfo info) {
    final active = info.entitlements.active;

    if (active.isEmpty) {
      currentSubscription = null;
      return;
    }

    final entitlement = active.values.first;

    currentSubscription = plans.firstWhere(
      (p) => p.id == entitlement.productIdentifier,
      orElse: () =>
          plans.isNotEmpty ? plans.first : throw Exception("No plans"),
    );
  }

  /// =========================
  /// PURCHASE FLOW
  /// =========================
  Future<bool> subscribeToPlan(String id) async {
    if (_isPurchasing) return false;

    try {
      _isPurchasing = true;
      notifyListeners();

      final package = _rcPackages.firstWhere((p) => p.identifier == id);

      final result = await Purchases.purchasePackage(package);

      _handleCustomerInfoUpdate(result.customerInfo);

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  /// =========================
  /// LISTENER UPDATE
  /// =========================
  void _handleCustomerInfoUpdate(CustomerInfo info) {
    _setCurrentSubscription(info);
    notifyListeners();
  }

  /// =========================
  /// UTILS
  /// =========================
  int _parseDuration(Period? period) {
    if (period == null) return 0;

    switch (period.unit) {
      case PeriodUnit.day:
        return period.value;
      case PeriodUnit.week:
        return period.value * 7;
      case PeriodUnit.month:
        return period.value * 30;
      case PeriodUnit.year:
        return period.value * 365;
      default:
        return 0;
    }
  }

  Future<void> fetchMySubscription() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();

      _handleCustomerInfoUpdate(customerInfo);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
