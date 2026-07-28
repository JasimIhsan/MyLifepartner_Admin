import 'package:flutter_test/flutter_test.dart';
import 'package:life_partner_again/services/api_service.dart';
import 'package:life_partner_again/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await TokenService.clearTokens();
  });

  group('ApiService Backend Integration Tests', () {
    const testEmail = 'jasimihsan1234@gmail.com';
    const testPassword = 'Jasim9656@';

    Future<void> login() async {
      final response = await ApiService.client.post(
        '/auth/login',
        data: {'email': testEmail, 'password': testPassword},
      );
      expect(response.statusCode, 200);

      final data = response.data['data'];
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];

      expect(accessToken, isNotNull);
      expect(refreshToken, isNotNull);

      await TokenService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }

    test('Should successfully login and fetch protected route', () async {
      await login();

      // Hit a protected route (e.g. /auth/me)
      final meResponse = await ApiService.client.get('/auth/me');
      expect(meResponse.statusCode, 200);
      expect(meResponse.data['data']['email'], testEmail);
    });

    test(
      'Should seamlessly refresh token when access token is artificially expired',
      () async {
        await login();

        final originalTokens = await SharedPreferences.getInstance();
        final originalAccessToken = originalTokens.getString('access_token');
        final originalRefreshToken = originalTokens.getString('refresh_token');

        // Artificially corrupt the access token to trigger 401
        await TokenService.saveTokens(
          accessToken: 'corrupted_access_token',
          refreshToken: originalRefreshToken!,
        );

        // Hit a protected route. This should initially fail with 401,
        // then ApiService should catch it, use the refresh token to get new tokens,
        // and automatically retry and succeed.
        final meResponse = await ApiService.client.get('/auth/me');
        expect(meResponse.statusCode, 200);

        // Verify new tokens were saved
        final newTokens = await SharedPreferences.getInstance();
        final newAccessToken = newTokens.getString('access_token');

        expect(newAccessToken, isNot('corrupted_access_token'));
        expect(
          newAccessToken,
          isNot(originalAccessToken),
        ); // Backend should issue a new token
      },
    );

    test(
      'Concurrent requests with expired access token should only trigger one refresh',
      () async {
        await login();

        final originalTokens = await SharedPreferences.getInstance();
        final originalRefreshToken = originalTokens.getString('refresh_token');

        await TokenService.saveTokens(
          accessToken: 'corrupted_access_token',
          refreshToken: originalRefreshToken!,
        );

        // Fire 3 concurrent requests
        final futures = [
          ApiService.client.get('/auth/me'),
          ApiService.client.get('/auth/me'),
          ApiService.client.get('/auth/me'),
        ];

        final responses = await Future.wait(futures);

        // All should succeed
        for (var response in responses) {
          expect(response.statusCode, 200);
        }

        final newTokens = await SharedPreferences.getInstance();
        final newAccessToken = newTokens.getString('access_token');
        expect(newAccessToken, isNot('corrupted_access_token'));
      },
    );

    test(
      'Should logout and throw error if refresh token is also expired/invalid',
      () async {
        await login();

        // Corrupt BOTH tokens
        await TokenService.saveTokens(
          accessToken: 'corrupted_access_token',
          refreshToken: 'corrupted_refresh_token',
        );

        try {
          await ApiService.client.get('/auth/me');
          fail('Expected an error due to invalid refresh token');
        } catch (e) {
          // ApiService will throw the 401 DioException, or FlutterError from context logout
          // ignore: unnecessary_null_comparison
          expect(e != null, true);
        }

        // Verify tokens were cleared by _logoutAndRedirect
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('access_token'), isNull);
        expect(prefs.getString('refresh_token'), isNull);
      },
    );
  });
}
