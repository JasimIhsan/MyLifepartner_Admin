import 'package:dio/dio.dart';
import 'package:life_partner_again/config/env.dart';
import 'package:life_partner_again/services/token_service.dart';

/// Service class for handling API requests using the Dio package.
/// This class is implemented as a Singleton to ensure only one instance
/// of Dio is used throughout the application.
class ApiService {
  /// The singleton instance of the ApiService.
  /// This variable stores the single instance of the class that will be reused.
  static final ApiService _instance = ApiService._internal();

  /// The Dio instance that will handle the HTTP requests.
  late final Dio dio;

  /// Private constructor to prevent external instantiation.
  /// This checks if an instance already exists; if not, it initializes the Dio client.
  ApiService._internal() {
    // Initialize Dio with base options.
    // BaseOptions allow us to configure common settings like the base URL,
    // timeouts, and headers that will be applied to every request.
    dio = Dio(
      BaseOptions(
        // The base URL for your API. All requests will be relative to this URL.
        baseUrl: Env.baseUrl,

        // Timeout for opening the connection to the server.
        connectTimeout: const Duration(seconds: 10),

        // Timeout for receiving data from the server.
        receiveTimeout: const Duration(seconds: 10),

        // Default headers to be sent with every request.
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors to the Dio instance.
    // Interceptors act as middleware, allowing us to hook into the request/response cycle.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await TokenService.getAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 &&
              !(e.requestOptions.path.contains('login') ||
                  e.requestOptions.path.contains('refresh-token'))) {
            final refreshToken = await TokenService.getRefreshToken();
            if (refreshToken != null) {
              try {
                final refreshDio = Dio(
                  BaseOptions(baseUrl: dio.options.baseUrl),
                );
                final response = await refreshDio.post(
                  '/user/auth/refresh-token',
                  data: {'refreshToken': refreshToken},
                );

                if (response.statusCode == 200 &&
                    response.data['data'] != null) {
                  final newAccessToken = response.data['data']['accessToken'];
                  final newRefreshToken = response.data['data']['refreshToken'];

                  if (newAccessToken != null && newRefreshToken != null) {
                    await TokenService.saveTokens(
                      accessToken: newAccessToken,
                      refreshToken: newRefreshToken,
                    );

                    // Retry original request
                    final opts = e.requestOptions;
                    opts.headers['Authorization'] = 'Bearer $newAccessToken';
                    final cloneReq = await dio.fetch(opts);
                    return handler.resolve(cloneReq);
                  }
                }
              } catch (refreshError) {
                await TokenService.clearTokens();
              }
            } else {
              await TokenService.clearTokens();
            }
          }
          return handler.next(e);
        },
      ),
    );

    // Here we add a LogInterceptor to print request/response details to the console for debugging.
    dio.interceptors.add(
      LogInterceptor(
        request: true, // Print request details
        requestBody: true, // Print request body
        responseBody: true, // Print response body
        responseHeader: false, // Don't print response headers (to reduce noise)
        error: true, // Print errors
      ),
    );
  }

  /// Factory constructor that returns the singleton instance.
  /// When you call `ApiService()`, this factory ensures you get back the
  /// same single instance created by `_internal`.
  factory ApiService() {
    return _instance;
  }

  /// Static getter for easy access to the Dio client instance.
  /// This allows you to call `ApiService.client.get(...)` directly from anywhere in your app.
  static Dio get client => _instance.dio;
}
