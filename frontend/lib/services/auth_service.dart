import 'package:dio/dio.dart';
import 'package:life_partner_again/models/onboarding_status.dart';
import 'package:life_partner_again/services/auth_repository.dart';
import 'package:life_partner_again/services/token_service.dart';

class AuthService {
  AuthService({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  Future<OnboardingStatus> fetchMeOrThrow() async {
    final res = await _authRepository.getMe();
    if (!res.success || res.data == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        error: res.message,
      );
    }
    return res.data!;
  }

  Future<void> logoutLocal() async {
    await TokenService.clearTokens();
  }
}
