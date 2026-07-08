import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRepository {
  Future<User> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await ApiService.client.get(
        '/$userId',
      );

      return User.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> updateUser({String? name, String? email}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;

      final response = await ApiService.client.patch(
        '/user/$userId',
        data: data,
      );

      return User.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}
