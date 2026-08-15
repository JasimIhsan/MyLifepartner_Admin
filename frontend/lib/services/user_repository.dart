import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/services/api_service.dart';

class UserRepository {
  static final _client = ApiService.client;

  Future<User> getUser() async {
    try {
      final response = await _client.get('/profile');

      return User.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> updateUser({String? name, String? email}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;

      final response = await _client.patch('/profile', data: data);

      return User.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> requestAccountDeletion({required String reason}) async {
    try {
      await _client.post('/account-deletion/request', data: {'reason': reason});
    } catch (e) {
      rethrow;
    }
  }
}

