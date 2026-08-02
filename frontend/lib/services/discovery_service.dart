import 'package:life_partner_again/models/discovery_filter.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/services/api_service.dart';

class DiscoveryService {
  static final _client = ApiService.client;

  static Future<Map<String, dynamic>> discoverProfiles({
    required DiscoveryFilter filter,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
      ...filter.toMap(),
    };

    try {
      final response = await _client.get(
        '/discovery/profiles',
        queryParameters: queryParams,
      );

      if (response.data == null) {
        throw Exception('Empty response from server');
      }

      if (response.data['success'] == false) {
        throw Exception(response.data['message'] ?? 'Failed to load profiles');
      }

      final data = response.data['data'];

      if (data == null) {
        throw Exception(response.data['message'] ?? 'Failed to load profiles');
      }

      final List<dynamic> profilesJson = data['profiles'] ?? [];
      final pagination = data['pagination'] ?? {};

      final profiles = profilesJson
          .map((json) => MatchRecommendation.fromJson(json))
          .toList();

      return {
        'profiles': profiles,
        'hasNextPage': pagination['hasNextPage'] ?? false,
        'total': pagination['total'] ?? 0,
      };
    } catch (e) {
      rethrow;
    }
  }
}
