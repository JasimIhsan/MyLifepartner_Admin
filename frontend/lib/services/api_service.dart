import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/config/env.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/main.dart';
import 'package:life_partner_again/services/token_service.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service class for handling API requests using Dio.
class ApiService {
  static final ApiService _instance = ApiService._internal();

  late final Dio dio;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await TokenService.getAccessToken();

          debugPrint("👉 Access Token: $accessToken");

          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }

          return handler.next(options);
        },

        onError: (DioException e, handler) async {
          final statusCode = e.response?.statusCode;
          final requestPath = e.requestOptions.path;

          final isUnauthorized = statusCode == 401;

          final isAuthRoute =
              requestPath.contains('login') ||
              requestPath.contains('register') ||
              requestPath.contains('refresh-token');

          final alreadyRetried = e.requestOptions.extra['retried'] == true;

          if (!isUnauthorized || isAuthRoute || alreadyRetried) {
            return handler.next(e);
          }

          final refreshToken = await TokenService.getRefreshToken();

          if (refreshToken == null || refreshToken.isEmpty) {
            await _logoutAndRedirect();
            return handler.next(e);
          }

          try {
            final refreshDio = Dio(
              BaseOptions(
                baseUrl: dio.options.baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'ngrok-skip-browser-warning': 'true',
                },
              ),
            );

            final refreshResponse = await refreshDio.post(
              '/auth/refresh-token',
              data: {'refreshToken': refreshToken},
            );

            if (refreshResponse.statusCode != 200 ||
                refreshResponse.data == null ||
                refreshResponse.data['data'] == null) {
              await _logoutAndRedirect();
              return handler.next(e);
            }

            final data = refreshResponse.data['data'];

            final newAccessToken = data['accessToken'];
            final newRefreshToken = data['refreshToken'];

            if (newAccessToken == null ||
                newAccessToken.toString().isEmpty ||
                newRefreshToken == null ||
                newRefreshToken.toString().isEmpty) {
              await _logoutAndRedirect();
              return handler.next(e);
            }

            await TokenService.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );

            final retryOptions = e.requestOptions;

            retryOptions.extra['retried'] = true;
            retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await dio.fetch(retryOptions);

            return handler.resolve(retryResponse);
          } catch (_) {
            await _logoutAndRedirect();
            return handler.next(e);
          }
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
    );
  }

  factory ApiService() {
    return _instance;
  }

  static Dio get client => _instance.dio;

  static Future<void> _logoutAndRedirect() async {
    await TokenService.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}
