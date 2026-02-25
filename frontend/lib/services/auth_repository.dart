import 'package:dio/dio.dart';
import 'package:mylifepartner/models/auth_response.dart';
import 'package:mylifepartner/models/country_detection_response.dart';
import 'package:mylifepartner/services/api_service.dart';
import 'package:mylifepartner/services/token_service.dart';

class AuthRepository {
  final Dio _dio = ApiService.client;

  Future<CountryDetectionResponse> detectCountry() async {
    try {
      final response = await _dio.get("/user/auth/detect-country");
      return CountryDetectionResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<SendOtpResponse> sendOtp({
    required String mobileNumber,
    required String sendOption,
  }) async {
    try {
      final response = await _dio.post(
        "/user/auth/send-otp",
        data: {"mobileNumber": mobileNumber, "sendOption": sendOption},
      );
      return SendOtpResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<SendOtpResponse> resendOtp({
    required String mobileNumber,
    required String sendOption,
  }) async {
    try {
      final response = await _dio.post(
        "/user/auth/resend-otp",
        data: {"mobileNumber": mobileNumber, "sendOption": sendOption},
      );
      return SendOtpResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<VerifyOtpResponse> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        "/user/auth/login",
        data: {"mobileNumber": mobileNumber, "otp": otp},
      );
      final verifyResponse = VerifyOtpResponse.fromJson(response.data);
      if (verifyResponse.success) {
        await TokenService.saveTokens(
          accessToken: verifyResponse.accessToken,
          refreshToken: verifyResponse.refreshToken,
        );
      }
      return verifyResponse;
    } catch (e) {
      rethrow;
    }
  }
}
