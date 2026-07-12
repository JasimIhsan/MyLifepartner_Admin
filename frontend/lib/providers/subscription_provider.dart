import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/config/env.dart';
import 'package:life_partner_again/models/subscription_plan.dart';
import 'package:life_partner_again/services/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  List<SubscriptionPlan> plans = [];
  SubscriptionPlan? currentSubscription;

  List<Package> _rcPackages = [];
  UserSubscription? _mySubscription;

  bool _isPurchasing = false;
  bool _isInitialized = false;
  final SubscriptionService _subscriptionService = SubscriptionService();
  String? _authenticatedUserId;

  /// =========================
  /// INIT (call once)
  /// =========================
  Future<void> init(String userId) async {
    _authenticatedUserId = userId;
    
    if (_isInitialized) return;

    try {
      await Purchases.configure(PurchasesConfiguration(Env.revenueCatApiKey));

      await Purchases.logIn(userId);

      Purchases.addCustomerInfoUpdateListener((info) {
        _handleCustomerInfoUpdate(info);
      });

      _isInitialized = true;
    } catch (e) {
      error = _getReadableError(e);
      notifyListeners();
    }
  }

  /// =========================
  /// IDENTITY VERIFICATION
  /// =========================
  Future<bool> _ensureRevenueCatIdentity(String userId) async {
    try {
      final appUserID = await Purchases.appUserID;
      if (appUserID != userId) {
         debugPrint("CRITICAL ERROR: RevenueCat identity mismatch! RC ID: $appUserID, Backend ID: $userId");
         await Purchases.logOut();
         await Purchases.logIn(userId);
         return true; // We forcefully logged them back in
      }
      return true;
    } catch (e) {
      debugPrint("Error checking RevenueCat identity: $e");
      return false;
    }
  }

  /// =========================
  /// LOGOUT
  /// =========================
  Future<void> logout() async {
    try {
      if (_isInitialized) {
        await Purchases.logOut();
      }
      _isInitialized = false;
      _authenticatedUserId = null;
      plans = [];
      currentSubscription = null;
      _rcPackages = [];
      _mySubscription = null;
      notifyListeners();
    } catch (e) {
      debugPrint("Error logging out from RevenueCat: $e");
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
      await _ensureRevenueCatIdentity(userId);

      final results = await Future.wait([
        _fetchBackendPlans(),
        _fetchRevenueCatPlans(),
        _fetchCustomerInfo(),
        _subscriptionService.getMySubscription(),
      ]);

      debugPrint("👉 results: $results");

      final backendPlans = results[0] as List<SubscriptionPlan>;
      final rcPackages = results[1] as List<Package>;
      final customerInfo = results[2] as CustomerInfo;
      _mySubscription = results[3] as UserSubscription?;

      _rcPackages = rcPackages;

      _mergePlans(backendPlans: backendPlans, rcPackages: rcPackages);

      _setCurrentSubscription(customerInfo);
    } catch (e) {
      error = _getReadableError(e);
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
      return plans; 
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
    try {
      final offerings = await Purchases.getOfferings();
      final packages = offerings.all.values
          .expand((e) => e.availablePackages)
          .toList();
      return packages;
    } catch (e, stack) {
      debugPrint("❌ Error fetching RevenueCat plans: $e");
      debugPrint("$stack");
      return [];
    }
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
      debugPrint(
        "⚠️ Subscription service (RevenueCat) is currently unavailable, falling back to backend prices.",
      );
    }

    final List<SubscriptionPlan> merged = [];

    for (final plan in backendPlans) {
      if (plan.price == 0) {
        merged.add(plan);
        continue;
      }

      final productId = plan.identifier ?? plan.id.toString();

      final match = rcPackages.where(
        (pkg) => pkg.storeProduct.identifier == productId,
      );

      if (match.isEmpty) {
        debugPrint(
          "⚠️ No match for backend plan ${plan.id} with productId=$productId. Falling back to backend price.",
        );
        merged.add(plan);
        continue;
      }

      final package = match.first;
      final product = package.storeProduct;

      merged.add(
        plan.copyWith(
          rcDisplayPrice: product.priceString,
          rcPrice: product.price,
          rcDurationTitle: _getDurationString(package.packageType),
        ),
      );
    }

    plans = merged;
  }

  String? _getDurationString(PackageType type) {
    switch (type) {
      case PackageType.annual:
        return '365 days';
      case PackageType.sixMonth:
        return '180 days';
      case PackageType.threeMonth:
        return '90 days';
      case PackageType.twoMonth:
        return '60 days';
      case PackageType.monthly:
        return '30 days';
      case PackageType.weekly:
        return '7 days';
      case PackageType.lifetime:
        return 'Lifetime';
      default:
        return null;
    }
  }

  /// =========================
  /// CURRENT SUBSCRIPTION PRECEDENCE
  /// =========================
  void _setCurrentSubscription(CustomerInfo info) {
    // 1. Active paid backend subscription
    if (_mySubscription != null &&
        _mySubscription!.isActive &&
        _mySubscription!.plan != null &&
        _mySubscription!.plan!.name.toUpperCase() != "FREE" &&
        _mySubscription!.plan!.price > 0) {
      final match = plans.where((p) => p.id == _mySubscription!.plan!.id);
      currentSubscription = match.isNotEmpty ? match.first : _mySubscription!.plan!;
      debugPrint("👉 currentSubscription [1. Backend Paid]: ${currentSubscription?.name}");
      return;
    }

    // 2. Active RevenueCat entitlement fallback
    final active = info.entitlements.active;
    if (active.isNotEmpty) {
      final entitlement = active.values.first;
      final match = plans.where(
        (p) => (p.identifier ?? p.id.toString()) == entitlement.productIdentifier,
      );

      if (match.isNotEmpty) {
        currentSubscription = match.first;
        debugPrint("👉 currentSubscription [2. RevenueCat Temporary UI Fallback]: ${currentSubscription?.name}");
        return;
      } else {
        final fallbackMatch = plans.where(
          (p) => p.name.toLowerCase() == entitlement.identifier.toLowerCase(),
        );
        if (fallbackMatch.isNotEmpty) {
          currentSubscription = fallbackMatch.first;
          debugPrint("👉 currentSubscription [2. RevenueCat Temporary UI Fallback]: ${currentSubscription?.name}");
          return;
        } else {
          debugPrint("⚠️ Could not match RevenueCat entitlement ${entitlement.identifier} to any backend plan.");
        }
      }
    }

    // 3. Backend FREE subscription fallback
    if (_mySubscription != null &&
        _mySubscription!.isActive &&
        _mySubscription!.plan != null) {
      final match = plans.where((p) => p.id == _mySubscription!.plan!.id);
      currentSubscription = match.isNotEmpty ? match.first : _mySubscription!.plan!;
      debugPrint("👉 currentSubscription [3. Backend FREE]: ${currentSubscription?.name}");
      return;
    }

    // 4. Null
    currentSubscription = null;
    debugPrint("👉 currentSubscription [4. Null]");
  }

  /// =========================
  /// PURCHASE FLOW
  /// =========================
  Future<bool> subscribeToPlan(String id) async {
    if (_isPurchasing || _authenticatedUserId == null) return false;
    
    // Safety identity verification before purchase
    bool identityOk = await _ensureRevenueCatIdentity(_authenticatedUserId!);
    if (!identityOk) {
       error = "Identity mismatch occurred. Please try restarting the app.";
       return false;
    }

    debugPrint("🔥 id: $id");

    try {
      _isPurchasing = true;
      notifyListeners();

      final backendPlan = plans.firstWhere(
        (p) => (p.identifier ?? p.id.toString()) == id,
      );

      if (backendPlan.price == 0) {
        final sub = await _subscriptionService.subscribe(backendPlan.id);
        _mySubscription = sub;

        try {
          final customerInfo = await Purchases.getCustomerInfo();
          _handleCustomerInfoUpdate(customerInfo);

          if (customerInfo.entitlements.active.isNotEmpty) {
            error = "Plan downgraded! Please remember to also cancel your active subscription in your App Store / Play Store settings so you aren't charged.";
            return false;
          }
        } catch (_) {}

        return true;
      }

      final package = _rcPackages.firstWhere(
        (p) => p.storeProduct.identifier == id,
      );

      // ignore: deprecated_member_use
      final result = await Purchases.purchasePackage(package);

      // Temporarily update UI locally before backend verifies
      _handleCustomerInfoUpdate(result.customerInfo);

      // Trigger verification and sync with the backend
      try {
         final syncedSub = await _subscriptionService.syncSubscription();
         if (syncedSub != null) {
           _mySubscription = syncedSub;
         }
      } catch (syncError) {
         debugPrint("Backend sync failed after purchase (will retry via webhook or later manually): $syncError");
         // We do NOT reset the UI fallback, because the user just paid. Let them see their plan locally.
      }

      // Re-trigger update in case backend sync changed things
      _handleCustomerInfoUpdate(result.customerInfo);

      return true;
    } catch (e) {
      error = _getReadableError(e);
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

  Future<void> fetchMySubscription() async {
    if (!_isInitialized || _authenticatedUserId == null) {
      debugPrint("⚠️ fetchMySubscription called but Purchases not initialized yet.");
      return;
    }
    try {
      await _ensureRevenueCatIdentity(_authenticatedUserId!);
      
      final customerInfo = await Purchases.getCustomerInfo();
      
      try {
        final syncedSub = await _subscriptionService.syncSubscription();
        if (syncedSub != null) {
          _mySubscription = syncedSub;
        }
      } catch (e) {
        debugPrint("fetchMySubscription: backend sync failed: $e");
      }

      _handleCustomerInfoUpdate(customerInfo);
    } catch (e) {
      error = _getReadableError(e);
      notifyListeners();
    }
  }

  String? get currentSubscriptionMessage => _mySubscription?.message;

  String _getReadableError(dynamic e) {
    if (e is PlatformException) {
      try {
        final errorCode = PurchasesErrorHelper.getErrorCode(e);
        if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
          return "Purchase was cancelled.";
        }
      } catch (_) {
      }
      return e.message ?? "A payment service error occurred. Please try again.";
    }
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring(11);
    }
    return "An unexpected error occurred. Please try again later.";
  }
}
