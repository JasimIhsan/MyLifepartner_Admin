import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/services/api_service.dart';

class MatchService {
  static final _client = ApiService.client;

  static Future<List<MatchRecommendation>> getRecommendations() async {
    final response = await _client.get('/matches/recommendations');
    final data = response.data;
    if (data['success'] == true) {
      final list = data['data'] as List<dynamic>;
      return list
          .map((e) => MatchRecommendation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<void> swipe({
    required int targetProfileId,
    required String action, // 'LEFT', 'RIGHT', 'UP'
  }) async {
    await _client.post(
      '/matches/swipe',
      data: {'targetProfileId': targetProfileId, 'action': action},
    );
  }

  static Future<Map<String, dynamic>?> getProfileDetail(int profileId) async {
    final response = await _client.get('/matches/profile/$profileId');
    final data = response.data;
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }
    return null;
  }

  static Future<List<MatchRecommendation>> getSentInterests() async {
    final response = await _client.get('/matches/interests/sent');
    final data = response.data;
    if (data['success'] == true) {
      final list = data['data'] as List<dynamic>;
      return list
          .map((e) => MatchRecommendation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<List<MatchRecommendation>> getReceivedInterests() async {
    final response = await _client.get('/matches/interests/received');
    final data = response.data;
    if (data['success'] == true) {
      final list = data['data'] as List<dynamic>;
      return list
          .map((e) => MatchRecommendation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<List<MatchRecommendation>> getMutualMatches() async {
    final response = await _client.get('/matches/mutual-matches');
    final data = response.data;
    if (data['success'] == true) {
      final list = data['data'] as List<dynamic>;
      return list
          .map((e) => MatchRecommendation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
