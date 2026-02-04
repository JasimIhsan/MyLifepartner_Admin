import 'package:dio/dio.dart';

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
        baseUrl: 'http://localhost:3000/api',

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
