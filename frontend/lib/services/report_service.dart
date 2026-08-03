import 'package:dio/dio.dart';
import 'package:life_partner_again/services/api_service.dart';

class ReportService {
  static final Dio _dio = ApiService.client;

  /// Submits a user report
  static Future<Map<String, dynamic>> submitReport({
    required int reportedUserId,
    required String reason,
    required String source,
    String? description,
    int? relatedMessageId,
    int? relatedConversationId,
    List<String>? screenshotPaths,
  }) async {
    try {
      final formData = FormData.fromMap({
        'reportedUserId': reportedUserId.toString(),
        'reason': reason,
        'source': source,
        if (description != null) 'description': description,
        if (relatedMessageId != null)
          'relatedMessageId': relatedMessageId.toString(),
        if (relatedConversationId != null)
          'relatedConversationId': relatedConversationId.toString(),
      });

      if (screenshotPaths != null && screenshotPaths.isNotEmpty) {
        for (var path in screenshotPaths) {
          formData.files.add(
            MapEntry(
              'screenshots',
              await MultipartFile.fromFile(path),
            ),
          );
        }
      }

      final response = await _dio.post(
        '/reports',
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to submit report');
      }
      throw Exception('Network error while submitting report');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
