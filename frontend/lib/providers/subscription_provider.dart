import 'package:flutter/foundation.dart';
import 'package:mylifepartner/models/subscription_plan.dart';
import 'package:mylifepartner/services/subscription_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();

  List<SubscriptionPlan> _plans = [];
  UserSubscription? _currentSubscription;
  bool _isLoading = false;
  String? _error;

  List<SubscriptionPlan> get plans => _plans;
  UserSubscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _plans = await _subscriptionService.getPlans();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMySubscription() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSubscription = await _subscriptionService.getMySubscription();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> subscribeToPlan(int planId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSubscription = await _subscriptionService.subscribe(planId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
