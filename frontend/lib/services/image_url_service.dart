import 'package:flutter/foundation.dart';
import 'package:life_partner_again/services/api_service.dart';

class ImageUrlService {
  static final _client = ApiService.client;

  static Future<String?> getPresignedUrl(String s3Key) async {
    try {
      final response = await _client.post(
        '/user/profile/presigned-url',
        data: {'key': s3Key},
      );
      if (response.statusCode == 200) {
        return response.data['data']['url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint("Failed to fetch presigned URL: $e");
      return null;
    }
  }
}
