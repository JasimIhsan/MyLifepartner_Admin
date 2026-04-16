import 'package:mylifepartner/services/api_service.dart';

class ChatApiService {
  static final _dio = ApiService.client;

  /// Send a message (persists to backend DB)
  static Future<Map<String, dynamic>?> sendMessage({
    required int receiverId,
    required String content,
    String messageType = 'TEXT',
    String? zegoMessageId,
  }) async {
    final response = await _dio.post('/chat/messages', data: {
      'receiverId': receiverId,
      'content': content,
      'messageType': messageType,
      if (zegoMessageId != null) 'zegoMessageId': zegoMessageId,
    });
    return response.data?['data'] as Map<String, dynamic>?;
  }

  /// Get all conversations for the current user
  static Future<List<dynamic>> getConversations() async {
    final response = await _dio.get('/chat/conversations');
    return response.data?['data'] as List<dynamic>? ?? [];
  }

  /// Get paginated messages for a conversation
  static Future<Map<String, dynamic>> getMessages(
    int conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/chat/conversations/$conversationId/messages',
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  /// Get ZEGOCLOUD access token
  static Future<Map<String, dynamic>?> getZegoToken() async {
    final response = await _dio.get('/zego/token');
    return response.data?['data'] as Map<String, dynamic>?;
  }

  /// Verify via backend if current user can initiate an audio or video call
  static Future<void> checkCallAccess({required String type}) async {
    await _dio.post(
      '/user/subscriptions/check-call',
      data: {'type': type},
    );
  }
}
