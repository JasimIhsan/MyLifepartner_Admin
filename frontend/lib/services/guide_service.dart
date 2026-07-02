import 'package:life_partner_again/services/api_service.dart';
import 'package:life_partner_again/models/guide_item.dart';

class GuideService {
  static final _client = ApiService.client;

  static Future<List<GuideItem>> getGuides({int? categoryId, String? search}) async {
    try {
      final response = await _client.get(
        '/user/guides',
        queryParameters: {
          if (categoryId != null && categoryId > 0) 'categoryId': categoryId,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data']['guides'];
        return data.map((json) => GuideItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  static Future<GuideItem?> getGuideById(int id) async {
    try {
      final response = await _client.get('/user/guides/$id');
      if (response.data['success'] == true) {
        return GuideItem.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
