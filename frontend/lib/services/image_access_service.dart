import 'package:flutter/foundation.dart';
import 'package:life_partner_again/services/api_service.dart';

class ImageAccessService {
  static final _client = ApiService.client;

  static Future<bool> requestAccess(int targetUserId) async {
    try {
      final response = await _client.post('/image-access/$targetUserId/request');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Request Access Failed: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getReceivedRequests() async {
    try {
      final response = await _client.get('/image-access/received');
      if (response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint("Get Received Requests Failed: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getSentRequests() async {
    try {
      final response = await _client.get('/image-access/sent');
      if (response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint("Get Sent Requests Failed: $e");
      return [];
    }
  }

  static Future<bool> approveRequest(int requestId) async {
    try {
      final response = await _client.patch('/image-access/$requestId/approve');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Approve Request Failed: $e");
      return false;
    }
  }

  static Future<bool> rejectRequest(int requestId) async {
    try {
      final response = await _client.patch('/image-access/$requestId/reject');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Reject Request Failed: $e");
      return false;
    }
  }

  static Future<bool> cancelRequest(int requestId) async {
    try {
      final response = await _client.patch('/image-access/$requestId/cancel');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Cancel Request Failed: $e");
      return false;
    }
  }

  static Future<bool> revokeRequest(int requestId) async {
    try {
      final response = await _client.patch('/image-access/$requestId/revoke');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Revoke Request Failed: $e");
      return false;
    }
  }
}
