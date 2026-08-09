import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/config/env.dart';
import 'package:life_partner_again/main.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/providers/theme_provider.dart';
import 'package:life_partner_again/services/token_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service class for handling API requests using Dio.
class ApiService {
  static final ApiService _instance = ApiService._internal();

  late final Dio dio;
  static Future<bool>? _refreshTokenFuture;

  ApiService._internal() {
    final headers = {
      if (!Env.isProduction) 'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: headers,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await TokenService.getAccessToken();

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
              requestPath.contains('refresh-token') ||
              requestPath.contains('otp');

          final alreadyRetried = e.requestOptions.extra['retried'] == true;

          if (!isUnauthorized || isAuthRoute || alreadyRetried) {
            return handler.next(e);
          }

          final refreshToken = await TokenService.getRefreshToken();

          if (refreshToken == null || refreshToken.isEmpty) {
            await ApiService.logoutAndRedirect();
            return handler.next(e);
          }

          if (_refreshTokenFuture != null) {
            final isRefreshed = await _refreshTokenFuture!;
            if (isRefreshed) {
              return await _retryRequest(e.requestOptions, handler);
            } else {
              return handler.next(e);
            }
          }

          _refreshTokenFuture = _performTokenRefresh(refreshToken);
          final isRefreshed = await _refreshTokenFuture!;
          _refreshTokenFuture = null;

          if (isRefreshed) {
            return await _retryRequest(e.requestOptions, handler);
          } else {
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

  Future<void> _retryRequest(
    RequestOptions requestOptions,
    ErrorInterceptorHandler handler,
  ) async {
    final newAccessToken = await TokenService.getAccessToken();
    final retryOptions = requestOptions;
    retryOptions.extra['retried'] = true;
    retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

    try {
      final retryResponse = await dio.fetch(retryOptions);
      return handler.resolve(retryResponse);
    } catch (err) {
      return handler.next(
        err is DioException
            ? err
            : DioException(requestOptions: retryOptions, error: err),
      );
    }
  }

  Future<bool> _performTokenRefresh(String refreshToken) async {
    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (!Env.isProduction) 'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      refreshDio.httpClientAdapter = dio.httpClientAdapter;

      final refreshResponse = await refreshDio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      final responseData = refreshResponse.data is String
          ? jsonDecode(refreshResponse.data)
          : refreshResponse.data;

      if (responseData == null || responseData['data'] == null) {
        await ApiService.logoutAndRedirect();
        return false;
      }

      final data = responseData['data'];
      final newAccessToken = data['accessToken'];
      final newRefreshToken = data['refreshToken'];

      if (newAccessToken == null ||
          newAccessToken.toString().isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.toString().isEmpty) {
        await ApiService.logoutAndRedirect();
        return false;
      }

      await TokenService.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      return true;
    } catch (_) {
      await ApiService.logoutAndRedirect();
      return false;
    }
  }

  static Future<void> logoutAndRedirect() async {
    await TokenService.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      context.read<ThemeProvider>().setThemeMode(ThemeMode.light);
      await context.read<AuthProvider>().logout();
    }
  }
}
