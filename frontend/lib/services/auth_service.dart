import 'package:dio/dio.dart';
import 'package:mylifepartner/models/onboarding_status.dart';
import 'package:mylifepartner/services/auth_repository.dart';
import 'package:mylifepartner/services/token_service.dart';

class AuthService {
  AuthService({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  Future<OnboardingStatus> fetchMeOrThrow() async {
    final res = await _authRepository.getMe();
    if (!res.success || res.data == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/user/auth/me'),
        error: res.message,
      );
    }
    return res.data!;
  }

  Future<void> logoutLocal() async {
    await TokenService.clearTokens();
  }
}

