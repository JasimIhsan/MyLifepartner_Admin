import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mylifepartner/models/profile_question.dart';
import 'package:mylifepartner/models/profile_section.dart';
import 'package:mylifepartner/models/user_image.dart';
import 'package:mylifepartner/services/api_service.dart';
import 'package:mylifepartner/utils/dio_error_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileRepository {
  Future<List<ProfileSection>> getSections({bool? isPrimary}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final queryParams = <String, dynamic>{};
      if (isPrimary != null) {
        queryParams['isPrimary'] = isPrimary;
      }

      final response = await ApiService.client.get(
        '/user/profile/sections',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ProfileSection.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load sections');
      }
    } catch (e) {
      debugPrint('Error fetching sections: $e');
      return [];
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
      throw Exception(
        getDioErrorMessage(e, fallback: 'Error fetching questions'),
      );
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
      throw Exception(getDioErrorMessage(e, fallback: 'Error saving answer'));
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
      throw Exception(
        getDioErrorMessage(e, fallback: 'Error completing profile'),
      );
    } catch (e) {
      throw Exception('Error completing profile: $e');
    }
  }

  Future<Map<String, dynamic>> getCompletionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await ApiService.client.get(
        '/user/profile/completion-status/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Failed to get completion status');
      }
    } on DioException catch (e) {
      throw Exception(
        getDioErrorMessage(e, fallback: 'Error fetching completion status'),
      );
    } catch (e) {
      throw Exception('Error fetching completion status: $e');
    }
  }

  Future<void> updateBasicProfile(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');

      if (userId == null) throw Exception('User not logged in');

      final response = await ApiService.client.patch(
        '/user/profile/basic-profile/$userId',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update basic profile');
      }
    } on DioException catch (e) {
      throw Exception(
        getDioErrorMessage(e, fallback: 'Error updating basic profile'),
      );
    } catch (e) {
      throw Exception('Error updating basic profile: $e');
    }
  }

  Future<void> updatePartnerPreference(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');

      if (userId == null) throw Exception('User not logged in');

      final response = await ApiService.client.patch(
        '/user/profile/partner-preference/$userId',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update partner preferences');
      }
    } on DioException catch (e) {
      throw Exception(
        getDioErrorMessage(e, fallback: 'Error updating partner preferences'),
      );
    } catch (e) {
      throw Exception('Error updating partner preferences: $e');
    }
  }

  Future<List<UserImage>> getUserImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');

      final response = await ApiService.client.get(
        '/user/profile/images/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return UserImageResponse.fromJson(response.data).data;
    } on DioException catch (e) {
      throw Exception(getDioErrorMessage(e, fallback: 'Error fetching images'));
    } catch (e) {
      throw Exception('Error fetching images: $e');
    }
  }

  Future<UserImage> uploadImage(XFile imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');

      final bytes = await imageFile.readAsBytes();

      final mimeType = imageFile.mimeType ?? 'image/jpeg';
      final mediaType = MediaType.parse(mimeType);

      FormData formData = FormData.fromMap({
        "image": MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name.isEmpty ? 'image.jpg' : imageFile.name,
          contentType: mediaType,
        ),
      });

      final response = await ApiService.client.post(
        '/user/profile/upload-image/$userId',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return UserImage.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(getDioErrorMessage(e, fallback: 'Error uploading image'));
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<void> uploadSelfie(XFile front, XFile left, XFile right, [double? latitude, double? longitude]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');

      final frontBytes = await front.readAsBytes();
      final leftBytes = await left.readAsBytes();
      final rightBytes = await right.readAsBytes();

      FormData formData = FormData.fromMap({
        "frontImage": MultipartFile.fromBytes(
          frontBytes,
          filename: front.name.isEmpty ? 'front.jpg' : front.name,
          contentType: MediaType.parse(front.mimeType ?? 'image/jpeg'),
        ),
        "leftImage": MultipartFile.fromBytes(
          leftBytes,
          filename: left.name.isEmpty ? 'left.jpg' : left.name,
          contentType: MediaType.parse(left.mimeType ?? 'image/jpeg'),
        ),
        "rightImage": MultipartFile.fromBytes(
          rightBytes,
          filename: right.name.isEmpty ? 'right.jpg' : right.name,
          contentType: MediaType.parse(right.mimeType ?? 'image/jpeg'),
        ),
      });

      if (latitude != null) {
        formData.fields.add(MapEntry('latitude', latitude.toString()));
      }
      if (longitude != null) {
        formData.fields.add(MapEntry('longitude', longitude.toString()));
      }

      final response = await ApiService.client.post(
        '/user/profile/upload-selfie/$userId',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to upload selfie');
      }
    } on DioException catch (e) {
      throw Exception(
        getDioErrorMessage(e, fallback: 'Error uploading selfie'),
      );
    } catch (e) {
      throw Exception('Error uploading selfie: $e');
    }
  }

  Future<void> removeImage(int imageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');

      final response = await ApiService.client.delete(
        '/user/profile/remove-image/$userId/$imageId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to remove image');
      }
    } on DioException catch (e) {
      throw Exception(getDioErrorMessage(e, fallback: 'Error removing image'));
    } catch (e) {
      throw Exception('Error removing image: $e');
    }
  }

  Future<void> setPrimaryImage(int imageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');

      final response = await ApiService.client.patch(
        '/user/profile/set-primary/$userId/$imageId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to set primary image');
      }
    } on DioException catch (e) {
      throw Exception(
        getDioErrorMessage(e, fallback: 'Error setting primary image'),
      );
    } catch (e) {
      throw Exception('Error setting primary image: $e');
    }
  }

  Future<void> completeImageUpload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');

      final response = await ApiService.client.post(
        '/user/profile/complete-image-upload/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to complete image upload');
      }

      await prefs.setBool('hasCompletedImageUpload', true);
    } on DioException catch (e) {
      throw Exception(
        getDioErrorMessage(e, fallback: 'Error completing image upload'),
      );
    } catch (e) {
      throw Exception('Error completing image upload: $e');
    }
  }

  Future<void> sendEmailVerificationLink({required String email}) async {
    try {
      final response = await ApiService.client.post(
        "/user/auth/send-magic-link",
        data: {"email": email},
      );
      if (response.statusCode != 200) {
        throw Exception("Failed to send email verification link");
      }
    } on DioException catch (e) {
      throw Exception(
        getDioErrorMessage(
          e,
          fallback: "Failed to send email verification link",
        ),
      );
    } catch (e) {
      throw Exception("Failed to send email verification link");
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    try {
      final response = await ApiService.client.post(
        "/user/auth/verify-email",
        data: {"token": token},
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception("Failed to verify email");
      }
    } on DioException catch (e) {
      throw Exception(
        getDioErrorMessage(e, fallback: "Failed to verify email link"),
      );
    } catch (e) {
      throw Exception("Failed to verify email link");
    }
  }
}
