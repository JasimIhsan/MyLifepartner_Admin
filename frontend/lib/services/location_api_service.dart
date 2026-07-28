import 'package:flutter/foundation.dart';
import 'package:life_partner_again/models/location_details.dart';
import 'package:life_partner_again/models/location_prediction.dart';
import 'package:life_partner_again/services/api_service.dart';

class LocationApiService {
  static final _client = ApiService.client;

  static Future<List<LocationPrediction>> searchLocations({
    required String query,
    required String type,
    required String sessionToken,
    String? countryCode,
    String? stateName,
  }) async {
    try {
      final queryParams = {
        'query': query,
        'type': type,
        'sessionToken': sessionToken,
      };

      if (countryCode != null) queryParams['countryCode'] = countryCode;
      if (stateName != null) queryParams['stateName'] = stateName;

      final response = await _client.get(
        '/locations/search',
        queryParameters: queryParams,
      );
      final data = response.data['data'] as List;
      return data.map((json) => LocationPrediction.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error searching locations: $e');
      return [];
    }
  }

  static Future<LocationDetails?> getPlaceDetails(String placeId) async {
    try {
      final response = await _client.get('/locations/place/$placeId');
      return LocationDetails.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('Error getting place details: $e');
      return null;
    }
  }

  static Future<LocationDetails?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _client.get(
        '/locations/reverse-geocode',
        queryParameters: {'latitude': latitude, 'longitude': longitude},
      );
      return LocationDetails.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      return null;
    }
  }
}
