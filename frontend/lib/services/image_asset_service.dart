import 'package:life_partner_again/models/image_asset.dart';
import 'package:life_partner_again/services/api_service.dart';

class ImageAssetService {
  static final _client = ApiService.client;

  static Future<List<ImageAsset>> getAssetsBySection(String section) async {
    try {
      final response = await _client.get('/image-assets/$section');

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ImageAsset.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
