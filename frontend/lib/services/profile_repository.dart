import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mylifepartner/models/profile_question.dart';
import 'package:mylifepartner/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileRepository {
  Future<int> getTotalSectionsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      // final userId = prefs.getInt('userId'); // Not strictly needed for general structure if public

      final response = await ApiService.client.get(
        '/user/profile/sections',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.length;
      } else {
        throw Exception('Failed to load sections count');
      }
    } catch (e) {
      // Return a default or rethrow.
      // If we fail, maybe default to 999 so we don't prematurely show "Complete"
      // or 0 to handle error in UI.
      debugPrint('Error fetching sections count: $e');
      return 0;
    }
  }

  Future<List<ProfileQuestion>> getQuestions(int sectionOrder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); // Assuming token is stored
      final userId = prefs.getInt('userId'); // Assuming userId is stored.
      // If userId not stored, maybe we get it from token or user provider.
      // For now, hardcoding or fetching from prefs.

      // FIX: The user snippet showed /api/user/profile/questions/1?sectionOrder=1
      // We need userId.

      if (userId == null) {
        // Fallback or throw error.
        // For dev, lets assume 1 if not found or handle gracefully
        // throw Exception('User not logged in');
      }

      final response = await ApiService.client.get(
        '/user/profile/questions/$userId',
        queryParameters: {'sectionOrder': sectionOrder},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ProfileQuestion.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load questions');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('message')) {
          throw Exception(data['message']);
        }
      }
      throw Exception('Error fetching questions: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching questions: $e');
    }
  }

  Future<void> saveAnswer(int questionId, dynamic answer) async {
    debugPrint('👉 Saving answer: $answer');
    debugPrint('👉 Question ID: $questionId');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');
      debugPrint('👉 Token: $token');
      debugPrint('👉 User ID: $userId');

      final response = await ApiService.client.post(
        '/user/profile/questions/save-answer/$userId/$questionId',
        data: {'answer': answer},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save answer');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('message')) {
          throw Exception(data['message']);
        }
      }
      throw Exception('Error saving answer: ${e.message}');
    } catch (e) {
      throw Exception('Error saving answer: $e');
    }
  }

  Future<void> completeProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await ApiService.client.patch(
        '/user/profile/complete/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to complete profile');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('message')) {
          throw Exception(data['message']);
        }
      }
      throw Exception('Error completing profile: ${e.message}');
    } catch (e) {
      throw Exception('Error completing profile: $e');
    }
  }
}
