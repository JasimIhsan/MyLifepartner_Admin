import 'package:dio/dio.dart';
import 'package:mylifepartner/services/api_service.dart';

class AuthRepository {
  final Dio _dio = ApiService.client;

  Future<Map<String, dynamic>> sendOtp({
    required String mobileNumber,
    required String sendOption,
  }) async {
    try {
      final response = await _dio.post(
        "/user/auth/send-otp",
        data: {"mobileNumber": mobileNumber, "sendOption": sendOption},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resendOtp({
    required String mobileNumber,
    required String sendOption,
  }) async {
    try {
      final response = await _dio.post(
        "/user/auth/resend-otp",
        data: {"mobileNumber": mobileNumber, "sendOption": sendOption},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        "/user/auth/login",
        data: {"mobileNumber": mobileNumber, "otp": otp},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
