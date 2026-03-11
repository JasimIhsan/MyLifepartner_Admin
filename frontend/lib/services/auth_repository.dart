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

  Future<InitiateAuthResponse> initiateAuth({required String email}) async {
    try {
      final response = await _dio.post(
        "/user/auth/initiate",
        data: {"email": email},
      );
      return InitiateAuthResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<SimpleMessageResponse> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        "/user/auth/verify-otp",
        data: {"email": email, "otp": otp},
      );
      return SimpleMessageResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResultResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "/user/auth/login",
        data: {"email": email, "password": password},
      );
      final verifyResponse = AuthResultResponse.fromJson(response.data);
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

  Future<AuthResultResponse> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "/user/auth/register",
        data: {"email": email, "password": password},
      );
      final verifyResponse = AuthResultResponse.fromJson(response.data);
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

  Future<SimpleMessageResponse> forgotPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "/user/auth/forgot-password",
        data: {"email": email, "password": password},
      );
      return SimpleMessageResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<SendOtpResponse> sendOtp({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        "/user/auth/send-otp",
        data: {"email": email},
      );
      return SendOtpResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<SendOtpResponse> resendOtp({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        "/user/auth/resend-otp",
        data: {"email": email},
      );
      return SendOtpResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
