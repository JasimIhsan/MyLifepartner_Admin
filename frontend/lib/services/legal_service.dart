import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:life_partner_again/services/api_service.dart';

class LegalService {
  static Future<Map<String, dynamic>?> getLatestTerms() async {
    try {
      final response = await ApiService.client.get('/legal/terms');
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
    } on DioException catch (e) {
      // Handle or log error
      debugPrint('Error fetching terms: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getLatestPrivacyPolicy() async {
    try {
      final response = await ApiService.client.get('/legal/privacy');
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
    } on DioException catch (e) {
      // Handle or log error
      debugPrint('Error fetching privacy policy: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getAcceptedDocument(String type) async {
    try {
      final response = await ApiService.client.get('/legal/accepted/$type');
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
    } on DioException catch (e) {
      debugPrint('Error fetching accepted $type: $e');
    }
    return null;
  }
}
