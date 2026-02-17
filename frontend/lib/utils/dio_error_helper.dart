import 'package:dio/dio.dart';

/// Returns a user-friendly error message for the given [DioException].
/// Optionally accepts a [fallback] message for non-network errors.
String getDioErrorMessage(DioException e, {String? fallback}) {
  const genericMessage = "We're facing some issues. Please try again later.";

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
    case DioExceptionType.cancel:
      return genericMessage;
    case DioExceptionType.badResponse:
      return e.response?.data?['message'] ?? fallback ?? genericMessage;
    default:
      return fallback ?? genericMessage;
  }
}
