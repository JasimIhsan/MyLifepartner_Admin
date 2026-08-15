import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/config/env.dart';
import 'package:life_partner_again/models/subscription_plan.dart';
import 'package:life_partner_again/services/subscription_service.dart';
import 'package:life_partner_again/widgets/bottomsheet/subscription/subscription_failure_ui.dart'
    show SubscriptionFailureType;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Internal sentinel thrown when the store returns no transaction identifier
/// (SCA / family-purchase approval / RC propagation lag). Treated as
/// [SubscriptionFailureType.pending] — NOT a hard error.
class _PurchasePendingException implements Exception {
  const _PurchasePendingException();
}

const String _androidPackageName = 'com.premiumglobalcorp.lifepartneragain';
const String _revenueCatUuidPrefix = '00000000-0000-4000-8000-';

String _revenueCatAppUserIdForUserId(String userId) {
  final trimmed = userId.trim();
  final parsed = BigInt.tryParse(trimmed);
  if (parsed == null || parsed.isNegative) return trimmed;

  final hexUserId = parsed.toRadixString(16);
  if (hexUserId.length > 12) return trimmed;

  return '$_revenueCatUuidPrefix${hexUserId.padLeft(12, '0')}';
}

/// Architecture contract
/// ─────────────────────────────────────────────────────────────────────
/// SOURCE OF TRUTH          │ USED FOR
/// Backend DB               │ Current plan, features, authorization
/// RevenueCat (RC)          │ Purchase flow, store transaction, pricing UI
/// ─────────────────────────────────────────────────────────────────────
///
/// Flutter NEVER reads RC entitlement state for authorization.
/// [currentSubscription] and [mySubscription] always come from the backend.
/// RC is only used for:
///   - purchase(PurchaseParams)
///   - restorePurchases()
///   - getOfferings() (for live store pricing display)
///
class SubscriptionProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  List<SubscriptionPlan> plans = [];
  SubscriptionPlan? currentSubscription;

  List<Package> _rcPackages = [];
  UserSubscription? _mySubscription;

  bool _isPurchasing = false;
  bool _isRevenueCatConfigured = false;
  bool _customerInfoListenerAttached = false;
  final SubscriptionService _subscriptionService = SubscriptionService();
  String? _authenticatedUserId;

  /// The failure category of the most recent failed purchase attempt.
  /// Reset to [SubscriptionFailureType.error] at the start of each purchase.
  SubscriptionFailureType _lastFailureType = SubscriptionFailureType.error;

  /// Returns the failure category for the most recent failed purchase.
  /// Consumers should read this immediately after [subscribeToPlan] returns
  /// `false` to render the appropriate failure UI.
  SubscriptionFailureType get lastFailureType => _lastFailureType;

  // ═══════════════════════════════════════════════════════════════════════
  // INIT (call once per session)
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> init(String userId) async {
    _authenticatedUserId = userId;

    try {
      final isConfigured =
          _isRevenueCatConfigured || await Purchases.isConfigured;
      if (!isConfigured) {
        final configuration = PurchasesConfiguration(Env.revenueCatApiKey)
          ..appUserID = _revenueCatAppUserIdForUserId(userId);
        await Purchases.configure(configuration);
      }

      _isRevenueCatConfigured = true;

      // RC listener is kept for purchase-flow UI responsiveness only.
      // It does NOT update authorization state — that comes from the backend.
      if (!_customerInfoListenerAttached) {
        Purchases.addCustomerInfoUpdateListener((_) {
          // No-op: backend is source of truth; no auth state updated here.
        });
        _customerInfoListenerAttached = true;
      }

      await _ensureRevenueCatIdentity(userId);
    } catch (e) {
      error = _getReadableError(e);
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // IDENTITY VERIFICATION
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> _ensureRevenueCatIdentity(String userId) async {
    try {
      final expectedAppUserId = _revenueCatAppUserIdForUserId(userId);
      final appUserID = await Purchases.appUserID;
      if (appUserID != expectedAppUserId) {
        debugPrint(
          '⚠️ RevenueCat identity mismatch! Current RC ID: $appUserID, '
          'Expected RC ID: $expectedAppUserId. Syncing identity...',
        );
        final logInResult = await Purchases.logIn(expectedAppUserId);
        final newAppUserId = logInResult.customerInfo.originalAppUserId;
        debugPrint(
          '✅ RevenueCat logged in successfully for user $expectedAppUserId '
          '(RC original app user ID: $newAppUserId)',
        );
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error verifying RevenueCat identity for user $userId: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> logout() async {
    try {
      if (_isRevenueCatConfigured || await Purchases.isConfigured) {
        await Purchases.logOut();
      }
      _authenticatedUserId = null;
      plans = [];
      currentSubscription = null;
      _rcPackages = [];
      _mySubscription = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error logging out from RevenueCat: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MAIN ENTRY — loads plans + current subscription
  // ═══════════════════════════════════════════════════════════════════════

  /// Loads everything needed to render the subscription screen.
  ///
  /// Calls /sync so that any changes made outside the app (cancellation,
  /// payment recovery, resubscription) are detected immediately — without
  /// waiting for a webhook.
  Future<void> loadSubscriptions(String userId) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      await init(userId);
      await _ensureRevenueCatIdentity(userId);

      // Run backend sync + RC pricing fetch in parallel.
      // /sync hits the RC REST API and returns the authoritative subscription.
      final results = await Future.wait([
        _fetchBackendPlans(),
        _fetchRevenueCatPackages(),
        _syncFromBackend(), // ← always sync on load to detect outside changes
      ]);

      final backendPlans = results[0] as List<SubscriptionPlan>;
      final rcPackages = results[1] as List<Package>;
      _mySubscription = results[2] as UserSubscription?;

      _rcPackages = rcPackages;
      _mergePlans(backendPlans: backendPlans, rcPackages: rcPackages);
      _applyCurrentSubscription();
    } catch (e) {
      error = _getReadableError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FETCH HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Future<List<SubscriptionPlan>> _fetchBackendPlans() async {
    try {
      debugPrint('🌐 Fetching backend plans...');
      final plans = await _subscriptionService.getPlans();
      debugPrint('✅ Backend plans count: ${plans.length}');
      return plans;
    } catch (e, stack) {
      debugPrint('❌ Error fetching backend plans: $e\n$stack');
      return [];
    }
  }

  Future<List<Package>> _fetchRevenueCatPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];
      if (packages.isEmpty) {
        return offerings.all.values.expand((e) => e.availablePackages).toList();
      }
      return packages;
    } catch (e, stack) {
      debugPrint('❌ Error fetching RevenueCat packages: $e\n$stack');
      return [];
    }
  }

  /// Calls /sync which fetches current state from the RC REST API and updates
  /// the backend DB, then returns the authoritative subscription record.
  ///
  /// This is the mechanism that makes cancellation, resubscription, and
  /// payment recovery appear immediately in the app — regardless of webhook
  /// delivery timing.
  Future<UserSubscription?> _syncFromBackend() async {
    try {
      return await _subscriptionService.syncSubscription();
    } catch (e) {
      debugPrint(
        '⚠️ Backend sync failed, falling back to /my-subscription: $e',
      );
      try {
        return await _subscriptionService.getMySubscription();
      } catch (e2) {
        debugPrint('❌ /my-subscription also failed: $e2');
        return null;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PLAN MERGE (backend metadata + RC pricing overlay)
  // ═══════════════════════════════════════════════════════════════════════

  void _mergePlans({
    required List<SubscriptionPlan> backendPlans,
    required List<Package> rcPackages,
  }) {
    if (backendPlans.isEmpty) {
      error = 'No plans available right now. Please try again later.';
      plans = [];
      return;
    }

    if (rcPackages.isEmpty) {
      debugPrint(
        '⚠️ RevenueCat packages unavailable — falling back to backend prices.',
      );
    }

    final List<SubscriptionPlan> merged = [];

    for (final plan in backendPlans) {
      if (plan.price == 0) {
        merged.add(plan);
        continue;
      }

      final productId = plan.identifier ?? plan.id.toString();

      final match = rcPackages.where((pkg) {
        final rcId = pkg.storeProduct.identifier;
        return rcId == productId || rcId.startsWith('$productId:');
      });

      if (match.isEmpty) {
        debugPrint(
          '⚠️ No RC package match for backend plan ${plan.id} '
          '(productId=$productId). Using backend price.',
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

  // ═══════════════════════════════════════════════════════════════════════
  // CURRENT SUBSCRIPTION — backend is the SOLE source of truth
  // ═══════════════════════════════════════════════════════════════════════

  /// Sets [currentSubscription] exclusively from [_mySubscription] (backend DB).
  ///
  /// RC entitlement state is NOT used here. If the backend says FREE, the user
  /// is FREE — period. This prevents stale RC entitlements from bypassing the
  /// backend's authoritative plan state.
  void _applyCurrentSubscription() {
    if (_mySubscription == null) {
      currentSubscription = null;
      debugPrint('👉 currentSubscription: null (no backend subscription)');
      return;
    }

    // Map the backend subscription to the enriched plan (with RC pricing).
    final match = plans.where((p) => p.id == _mySubscription!.planId);
    currentSubscription = match.isNotEmpty
        ? match.first
        : _mySubscription!.plan;
    debugPrint(
      '👉 currentSubscription [Backend]: ${currentSubscription?.name} '
      '(status=${_mySubscription!.status}, isActive=${_mySubscription!.isActive})',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PURCHASE FLOW
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> subscribeToPlan(
    String id, {
    VoidCallback? onPurchaseCompleted,
  }) async {
    if (_isPurchasing || _authenticatedUserId == null) return false;

    final identityOk = await _ensureRevenueCatIdentity(_authenticatedUserId!);
    if (!identityOk) {
      error = 'Unable to verify user session. Please try logging in again.';
      return false;
    }

    debugPrint('🔥 subscribeToPlan id: $id');

    // Reset failure type for this new attempt.
    _lastFailureType = SubscriptionFailureType.error;

    try {
      _isPurchasing = true;
      notifyListeners();

      final backendPlan = plans.firstWhere(
        (p) => (p.identifier ?? p.id.toString()) == id,
      );

      // ── FREE plan (direct backend subscribe) ───────────────────────────
      if (backendPlan.price == 0) {
        onPurchaseCompleted?.call();
        final sub = await _subscriptionService.subscribe(backendPlan.id);
        _mySubscription = sub;
        _applyCurrentSubscription();

        // Warn if user still has a paid RC entitlement active
        try {
          final customerInfo = await Purchases.getCustomerInfo();
          if (customerInfo.entitlements.active.isNotEmpty) {
            final String storeName =
                (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.macOS)
                ? 'App Store'
                : (defaultTargetPlatform == TargetPlatform.android)
                ? 'Google Play Store'
                : 'App Store / Play Store';

            error =
                'Plan downgraded! Please also cancel your active subscription '
                'in your $storeName settings to stop being charged.';
            return false;
          }
        } catch (_) {}

        return true;
      }

      // ── Paid plan (RC purchase → backend verify) ───────────────────────
      final storeProductId = backendPlan.identifier;

      final package = _rcPackages.firstWhere(
        (p) {
          final rcId = p.storeProduct.identifier;
          return rcId == id ||
              (storeProductId != null &&
                  (rcId == storeProductId ||
                      rcId.startsWith('$storeProductId:')));
        },
        orElse: () {
          final available = _rcPackages
              .map((p) => p.storeProduct.identifier)
              .join(', ');
          debugPrint(
            '⚠️ Product "$storeProductId" not in RC offerings. '
            'Available: $available',
          );
          throw Exception(
            'Product not found in store offerings. '
            'Available packages: ${available.isEmpty ? 'None (Check RevenueCat Current Offering)' : available}',
          );
        },
      );

      debugPrint('🎯 Package: ${package.storeProduct}');

      final result = await Purchases.purchase(
        PurchaseParams.package(
          package,
          productChangeInfo: _buildAndroidProductChangeInfo(backendPlan),
        ),
      );

      onPurchaseCompleted?.call();

      // ── Immediately verify the purchase with the backend ───────────────
      // This is the key path: we activate the plan NOW, without waiting for
      // a webhook. The backend verifies against RC's REST API and writes the
      // subscription record atomically.
      try {
        final customerInfo = result.customerInfo;

        final purchasedProductId =
            result.storeTransaction.productIdentifier.isNotEmpty
            ? result.storeTransaction.productIdentifier
            : package.storeProduct.identifier;
        final subscriptionInfo =
            _subscriptionInfoForProduct(customerInfo, purchasedProductId) ??
            _subscriptionInfoForProduct(
              customerInfo,
              package.storeProduct.identifier,
            );

        final storeTransactionId = _firstNonEmpty([
          subscriptionInfo?.storeTransactionId,
          result.storeTransaction.transactionIdentifier,
        ]);

        if (storeTransactionId == null) {
          // No transaction ID yet — this happens during iOS SCA / family
          // purchase approval or when RC hasn't propagated. Treat as pending:
          // throw the sentinel so the verifyError catch attempts /sync first.
          debugPrint(
            '⚠️ No storeTransactionId returned. '
            'Treating as pending — attempting /sync...',
          );
          throw const _PurchasePendingException();
        }

        // Determine store string expected by the backend.
        String store = 'PLAY_STORE';
        if (Platform.isIOS || Platform.isMacOS) {
          store = 'APP_STORE';
        }

        final verified = await _subscriptionService.verifyPurchase(
          storeTransactionId: storeTransactionId,
          productId: purchasedProductId,
          store: store,
          environment: (subscriptionInfo?.isSandbox ?? kDebugMode)
              ? 'SANDBOX'
              : 'PRODUCTION',
        );

        _mySubscription = verified;
        _applyCurrentSubscription();

        debugPrint(
          '✅ Purchase verified immediately. '
          'Plan: ${_mySubscription?.plan?.name}, '
          'Status: ${_mySubscription?.status}',
        );
      } catch (verifyError) {
        // _PurchasePendingException OR a network / API verify failure.
        // Both paths attempt /sync first — if sync also shows no active sub,
        // the pending sentinel sets lastFailureType = pending.
        final isPendingSentinel = verifyError is _PurchasePendingException;
        debugPrint(
          isPendingSentinel
              ? '⏳ Purchase pending — attempting /sync to confirm...'
              : '⚠️ /verify-purchase failed ($verifyError). Falling back to /sync...',
        );

        try {
          final synced = await _subscriptionService.syncSubscription();
          if (synced != null) {
            _mySubscription = synced;
            _applyCurrentSubscription();
            // /sync confirmed an active subscription — clear any pending flag.
            debugPrint('✅ /sync confirmed active plan after pending/verify-fail.');
          } else if (isPendingSentinel) {
            // /sync also returned null — payment is genuinely pending in the
            // store. Signal the UI to show the processing state.
            debugPrint(
              '⏳ /sync found no active sub — payment is still pending.',
            );
            _lastFailureType = SubscriptionFailureType.pending;
            error =
                'Your payment is being reviewed by the store. '
                'This usually takes a few seconds. If access doesn\'t '
                'activate automatically, tap Restore Purchases below.';
            return false;
          }
        } catch (syncError) {
          debugPrint(
            '⚠️ /sync fallback also failed ($syncError). '
            'Webhook will reconcile shortly.',
          );
          // If this started as a pending sentinel and sync failed too,
          // still surface the pending UI rather than a generic error.
          if (isPendingSentinel) {
            _lastFailureType = SubscriptionFailureType.pending;
            error =
                'Your payment is being reviewed by the store. '
                'If access doesn\'t activate automatically, tap '
                'Restore Purchases below.';
            return false;
          }
          // User sees their plan from the last known DB state. Webhook will
          // correct it within seconds.
        }
      }

      return true;
    } catch (e) {
      if (e is PlatformException) {
        try {
          final errorCode = PurchasesErrorHelper.getErrorCode(e);
          if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
            debugPrint(
              'ℹ️ Product already purchased. Triggering restore/sync...',
            );
            onPurchaseCompleted?.call();
            return restorePurchases();
          }
          // paymentPendingError = store-level deferral (carrier billing,
          // family approval, etc.). Not a retry-able error — mark as pending.
          if (errorCode == PurchasesErrorCode.paymentPendingError) {
            debugPrint(
              '⏳ paymentPendingError from RC — marking as pending.',
            );
            _lastFailureType = SubscriptionFailureType.pending;
          } else if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
            _lastFailureType = SubscriptionFailureType.cancelled;
          }
        } catch (_) {}
      }
      error = _getReadableError(e);
      return false;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRE-FLIGHT STATUS CHECK
  // ═══════════════════════════════════════════════════════════════════════

  /// Fetches a fresh subscription status from the backend **before** opening
  /// the store payment sheet.
  ///
  /// Returns a [PurchaseBlockReason] if the purchase should be prevented,
  /// or `null` if it is safe to proceed.  Also refreshes the provider's
  /// [_mySubscription] and [currentSubscription] state so that any routing
  /// in [handleSubscribe] is based on current — not stale cached — data.
  ///
  /// Network errors are intentionally swallowed: a failed pre-flight must
  /// never block the user from purchasing.
  Future<PurchaseBlockReason?> checkStatusBeforePayment(
    SubscriptionPlan plan,
  ) async {
    try {
      debugPrint('🔍 Pre-flight: fetching fresh subscription status...');
      final fresh = await _subscriptionService.getMySubscription();
      _mySubscription = fresh;
      _applyCurrentSubscription();
      notifyListeners();

      if (fresh == null || !fresh.isActive) {
        debugPrint('✅ Pre-flight: no active sub — safe to proceed.');
        return null;
      }

      // User is on the same paid plan and it is active — block duplicate.
      if (plan.price > 0 && fresh.planId == plan.id) {
        debugPrint(
          '🚫 Pre-flight: user is already on plan ${plan.id} — blocking.',
        );
        return PurchaseBlockReason.alreadyOnPlan;
      }

      debugPrint('✅ Pre-flight: different plan or free — safe to proceed.');
      return null;
    } catch (e) {
      // Network / API failure: fail open so users aren't blocked.
      debugPrint('⚠️ Pre-flight check failed ($e) — allowing purchase.');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FETCH / REFRESH
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> restorePurchases() async {
    if (_authenticatedUserId == null) {
      error = 'Unable to restore purchases because you are not logged in.';
      notifyListeners();
      return false;
    }

    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final identityOk = await _ensureRevenueCatIdentity(_authenticatedUserId!);
      if (!identityOk) {
        error = 'Unable to verify user session. Please try logging in again.';
        return false;
      }

      await Purchases.restorePurchases();
      await Purchases.invalidateCustomerInfoCache();

      final syncedSub = await _syncFromBackend();
      if (syncedSub != null) {
        _mySubscription = syncedSub;
      } else {
        _mySubscription = await _subscriptionService.getMySubscription();
      }

      _applyCurrentSubscription();

      final restoredPaidSubscription =
          _mySubscription?.isActive == true &&
          (currentSubscription?.price ?? 0) > 0;

      if (!restoredPaidSubscription) {
        error =
            'No active subscription purchases were found for this store account.';
        return false;
      }

      error = null;
      return true;
    } catch (e) {
      error = _getReadableError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes the current subscription state from the backend.
  ///
  /// Calls /sync so that cancellations, resubscriptions, and payment
  /// recoveries are detected immediately — regardless of webhook delivery.
  ///
  /// Call this:
  ///   - When returning from the subscription management page (Play Store /
  ///     App Store) after a cancel or resubscribe action.
  ///   - When the app resumes from background.
  ///   - After calling restorePurchases().
  Future<void> fetchMySubscription() async {
    if (_authenticatedUserId == null) {
      debugPrint('⚠️ fetchMySubscription: not initialized yet.');
      return;
    }
    try {
      await _ensureRevenueCatIdentity(_authenticatedUserId!);

      // Invalidate RC cache so it re-fetches from the store.
      await Purchases.invalidateCustomerInfoCache();

      // /sync fetches fresh state from RC REST API → updates DB → returns it.
      final syncedSub = await _subscriptionService.syncSubscription();
      if (syncedSub != null) {
        _mySubscription = syncedSub;
      } else {
        // If sync returned null (user has no RC subscription), read DB state.
        _mySubscription = await _subscriptionService.getMySubscription();
      }

      _applyCurrentSubscription();
      notifyListeners();
    } catch (e) {
      error = _getReadableError(e);
      notifyListeners();
    }
  }

  /// Convenience retry loop used after opening subscription management.
  Future<void> refreshWithRetry({
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      debugPrint('🔄 Subscription refresh retry ${i + 1}/$maxRetries...');
      await fetchMySubscription();
      if (i < maxRetries - 1) {
        await Future.delayed(delay);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SUBSCRIPTION MANAGEMENT URLS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> openGooglePlaySubscription() async {
    return openStoreSubscriptionManagement();
  }

  Future<void> openStoreSubscriptionManagement() async {
    try {
      final info = await Purchases.getCustomerInfo();

      // Use RC's native management URL if available
      if (info.managementURL != null && info.managementURL!.isNotEmpty) {
        final Uri uri = Uri.parse(info.managementURL!);
        debugPrint('🚀 Launching native management URL: $uri');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      final Uri uri;
      if (Platform.isIOS) {
        uri = Uri.parse('https://apps.apple.com/account/subscriptions');
      } else {
        String? sku;
        if (info.entitlements.active.isNotEmpty) {
          sku = info.entitlements.active.values.first.productIdentifier;
        }
        if (sku != null && sku.isNotEmpty) {
          uri = Uri.parse(
            'https://play.google.com/store/account/subscriptions'
            '?sku=$sku&package=$_androidPackageName',
          );
        } else {
          uri = Uri.parse(
            'https://play.google.com/store/account/subscriptions',
          );
        }
      }

      debugPrint('🚀 Launching subscription URL: $uri');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('⚠️ Could not launch URL: $uri');
      }
    } catch (e) {
      debugPrint('❌ Error launching subscription page: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DEBUG HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> cancelSubscriptionDebug() async {
    if (!kDebugMode) return;
    try {
      final freePlan = plans.firstWhere((p) => p.price == 0);
      final sub = await _subscriptionService.subscribe(freePlan.id);
      _mySubscription = sub;
      _applyCurrentSubscription();

      await Purchases.invalidateCustomerInfoCache();
      await fetchMySubscription();
    } catch (e) {
      debugPrint('Error cancelling subscription in debug mode: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // COMPUTED GETTERS — all read from backend subscription
  // ═══════════════════════════════════════════════════════════════════════

  String? get currentSubscriptionMessage => _mySubscription?.message;
  UserSubscription? get mySubscription => _mySubscription;

  bool get hasBillingIssue => _mySubscription?.hasBillingIssue ?? false;
  bool get isInGracePeriod => _mySubscription?.isInGracePeriod ?? false;
  bool get isCancelledButActive =>
      _mySubscription?.isCancelledButActive ?? false;
  bool get isDowngradeScheduled =>
      _mySubscription?.isDowngradeScheduled ?? false;
  bool get isExpired => _mySubscription?.isExpired ?? false;
  bool get isCancelled => _mySubscription?.isCancelled ?? false;

  /// Convenience getter for loading subscription state.
  Future<void> loadSubscription() => fetchMySubscription();

  StoreProductChangeInfo? _buildAndroidProductChangeInfo(
    SubscriptionPlan targetPlan,
  ) {
    if (!Platform.isAndroid) return null;

    final currentPlan = currentSubscription;
    if (currentPlan == null || currentPlan.price == 0) return null;

    final oldProductIdentifier = currentPlan.identifier;
    final targetIdentifier = targetPlan.identifier ?? targetPlan.id.toString();
    if (oldProductIdentifier == null ||
        oldProductIdentifier.isEmpty ||
        oldProductIdentifier == targetIdentifier) {
      return null;
    }

    final replacementMode = targetPlan.price >= currentPlan.price
        ? StoreReplacementMode.chargeProratedPrice
        : StoreReplacementMode.deferred;

    return StoreProductChangeInfo(
      oldProductIdentifier,
      replacementMode: replacementMode,
    );
  }

  SubscriptionInfo? _subscriptionInfoForProduct(
    CustomerInfo customerInfo,
    String productId,
  ) {
    final matches = customerInfo.subscriptionsByProductIdentifier.entries
        .where((entry) {
          final key = entry.key;
          return key == productId ||
              key.startsWith('$productId:') ||
              productId.startsWith('$key:');
        })
        .map((entry) => entry.value)
        .toList();

    if (matches.isEmpty) return null;

    matches.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      final aPurchase = DateTime.tryParse(a.purchaseDate);
      final bPurchase = DateTime.tryParse(b.purchaseDate);
      if (aPurchase != null && bPurchase != null) {
        return bPurchase.compareTo(aPurchase);
      }
      return 0;
    });

    return matches.first;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ERROR FORMATTING
  // ═══════════════════════════════════════════════════════════════════════

  String _getReadableError(dynamic e) {
    if (e is PlatformException) {
      try {
        final errorCode = PurchasesErrorHelper.getErrorCode(e);
        switch (errorCode) {
          case PurchasesErrorCode.purchaseCancelledError:
            return 'Purchase was cancelled.';
          case PurchasesErrorCode.storeProblemError:
            return 'Unable to connect to the store. Please check your internet connection or try again later.';
          case PurchasesErrorCode.purchaseNotAllowedError:
            return 'In-app purchases are disabled or not allowed on this device.';
          case PurchasesErrorCode.purchaseInvalidError:
            return 'The selected plan or payment details are invalid. Please try again.';
          case PurchasesErrorCode.productNotAvailableForPurchaseError:
            return 'This plan is currently not available in your store region.';
          case PurchasesErrorCode.productAlreadyPurchasedError:
            return 'You are already subscribed to this plan.';
          case PurchasesErrorCode.networkError:
            return 'Network connection issue. Please check your internet connection and try again.';
          case PurchasesErrorCode.paymentPendingError:
            // Message is shown in the pending UI — keep it descriptive.
            return 'Your payment is being reviewed by the store. '
                'If access doesn\'t activate automatically, tap '
                'Restore Purchases below.';
          case PurchasesErrorCode.insufficientPermissionsError:
            return 'Permission denied. Please check your store payment settings.';
          default:
            return e.message ??
                'A payment service error occurred. Please try again.';
        }
      } catch (_) {}
      return e.message ?? 'A payment service error occurred. Please try again.';
    }
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring(11);
    }
    return 'An unexpected error occurred. Please try again later.';
  }
}

/// Reason why a purchase was blocked at the pre-flight stage.
enum PurchaseBlockReason {
  /// The user already has an active subscription to the requested plan.
  alreadyOnPlan,
}
