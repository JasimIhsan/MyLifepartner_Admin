import 'package:mylifepartner/services/api_service.dart';
import 'package:mylifepartner/models/image_asset.dart';

class ImageAssetService {
  static final _client = ApiService.client;

  static Future<List<ImageAsset>> getAssetsBySection(String section) async {
    try {
      final response = await _client.get('/user/image-assets/$section');
      
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
