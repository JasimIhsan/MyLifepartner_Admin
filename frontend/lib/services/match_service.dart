import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/services/api_service.dart';

class MatchService {
  static final _client = ApiService.client;

  static Future<List<MatchRecommendation>> getRecommendations() async {
    final response = await _client.get('/match/recommendations');
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
      '/match/swipe',
      data: {'targetProfileId': targetProfileId, 'action': action},
    );
  }

  static Future<Map<String, dynamic>?> getProfileDetaile(int profileId) async {
    final response = await _client.get('/match/profile/$profileId');
    final data = response.data;
    if (data['success'] == true) {
      return _normalizeProfileImages(data['data'] as Map<String, dynamic>);
    }
    return null;
  }

  static Future<List<MatchRecommendation>> getSentInterests() async {
    final response = await _client.get('/match/interests/sent');
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
    final response = await _client.get('/match/interests/received');
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
    final response = await _client.get('/match/mutual-match');
    final data = response.data;
    if (data['success'] == true) {
      final list = data['data'] as List<dynamic>;
      return list
          .map((e) => MatchRecommendation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<bool> cancelInterest(int targetProfileId) async {
    final response = await _client.post(
      '/match/swipe/cancel',
      data: {'targetProfileId': targetProfileId},
    );
    return response.data['success'] == true;
  }

  static Map<String, dynamic> _normalizeProfileImages(
    Map<String, dynamic> profile,
  ) {
    return {...profile, 'images': _normalizeImages(profile['images'])};
  }

  static List<dynamic> _normalizeImages(dynamic rawImages) {
    if (rawImages is! List) return [];

    return rawImages.map((rawImage) {
      if (rawImage is! Map) return rawImage;

      final image = Map<String, dynamic>.from(rawImage);
      final imageId = image['imageId'] ?? image['id'];
      final imageUrl =
          image['presignedImageUrl'] ?? image['imageUrl'] ?? image['url'];

      if (imageId != null) {
        image['imageId'] = imageId;
        image['id'] ??= imageId;
      }
      if (imageUrl != null) {
        image['presignedImageUrl'] = imageUrl;
        image['imageUrl'] = imageUrl;
      }

      return image;
    }).toList();
  }
}
