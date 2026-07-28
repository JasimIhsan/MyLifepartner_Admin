import 'package:dio/dio.dart';
import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/models/onboarding_status.dart';
import 'package:life_partner_again/services/api_service.dart';
import 'package:life_partner_again/services/token_service.dart';

class AuthRepository {
  final Dio _dio = ApiService.client;

  Future<OnboardingStatusResponse> getMe() async {
    try {
      final response = await _dio.get("/auth/me");
      return OnboardingStatusResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<InitiateAuthResponse> initiateAuth({required String email}) async {
    try {
      final response = await _dio.post(
        "/auth/initiate",
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
    String purpose = "auth",
  }) async {
    try {
      final response = await _dio.post(
        "/auth/verify-otp",
        data: {"email": email, "otp": otp, "purpose": purpose},
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
        "/auth/login",
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

  Future<AuthResultResponse> googleSignIn({
    required String idToken,
  }) async {
    try {
      final response = await _dio.post(
        "/oauth/google",
        data: {"idToken": idToken},
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
        "/auth/register",
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
        "/auth/forgot-password",
        data: {"email": email, "password": password},
      );
      return SimpleMessageResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<SendOtpResponse> sendOtp({
    required String email,
    String purpose = "auth",
  }) async {
    try {
      final response = await _dio.post(
        "/auth/send-otp",
        data: {"email": email, "purpose": purpose},
      );
      return SendOtpResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<SendOtpResponse> resendOtp({
    required String email,
    String purpose = "auth",
  }) async {
    try {
      final response = await _dio.post(
        "/auth/resend-otp",
        data: {"email": email, "purpose": purpose},
      );
      return SendOtpResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
