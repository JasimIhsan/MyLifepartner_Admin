import 'package:dio/dio.dart';
import 'package:life_partner_again/services/api_service.dart';

class BlockService {
  static final _client = ApiService.client;

  Future<void> blockUser(int userId) async {
    try {
      await _client.post('/blocks/$userId');
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to block user');
      }
      throw Exception('Failed to block user: $e');
    }
  }

  Future<void> unblockUser(int userId) async {
    try {
      await _client.delete('/blocks/$userId');
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to unblock user',
        );
      }
      throw Exception('Failed to unblock user: $e');
    }
  }

  Future<List<dynamic>> getBlockedUsers() async {
    try {
      final response = await _client.get('/blocks');
      if (response.statusCode == 200) {
        return response.data['data'] as List<dynamic>;
      }
      throw Exception('Failed to get blocked users');
    } catch (e) {
      throw Exception('Failed to get blocked users: $e');
    }
  }
}
