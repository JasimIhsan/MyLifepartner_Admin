import 'package:life_partner_again/models/subscription_plan.dart';
import 'package:life_partner_again/models/user_feature.dart';
import 'package:life_partner_again/services/api_service.dart';

class SubscriptionService {
  final _apiService = ApiService();

  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final response = await _apiService.dio.get('/subscription/plans');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((json) => SubscriptionPlan.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch plans');
    } catch (e) {
      throw Exception('Failed to load subscription plans: $e');
    }
  }

  Future<UserSubscription?> getMySubscription() async {
    try {
      final response = await _apiService.dio.get(
        '/subscription/my-subscription',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (response.data['data'] == null) return null;
        return UserSubscription.fromJson(response.data['data']);
      }
      throw Exception(
        response.data['message'] ?? 'Failed to fetch subscription',
      );
    } catch (e) {
      throw Exception('Failed to load current subscription: $e');
    }
  }

  Future<UserSubscription> subscribe(int planId) async {
    try {
      final response = await _apiService.dio.post(
        '/subscription/subscribe',
        data: {'planId': planId},
      );
      if (response.statusCode == 201 && response.data['success'] == true) {
        return UserSubscription.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to subscribe');
    } catch (e) {
      throw Exception('Failed to subscribe: $e');
    }
  }

  Future<UserFeature?> getUserFeatures() async {
    try {
      final response = await _apiService.dio.get('/subscription/features');
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (response.data['data'] == null) return null;
        return UserFeature.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch features');
    } catch (e) {
      throw Exception('Failed to load user features: $e');
    }
  }

  Future<UserSubscription?> syncSubscription() async {
    try {
      final response = await _apiService.dio.post('/subscription/sync');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data['data'];
        if (responseData == null || responseData['subscription'] == null) {
          return null;
        }
        return UserSubscription.fromJson(responseData['subscription']);
      }
      throw Exception(
        response.data['message'] ?? 'Failed to sync subscription',
      );
    } catch (e) {
      throw Exception('Failed to sync subscription: $e');
    }
  }
}
