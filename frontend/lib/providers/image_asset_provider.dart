import 'package:flutter/foundation.dart';
import 'package:life_partner_again/models/image_asset.dart';
import 'package:life_partner_again/services/image_asset_service.dart';

enum ImageAssetLoadState { idle, loading, loaded, error }

class ImageAssetProvider extends ChangeNotifier {
  final Map<String, List<ImageAsset>> _sectionAssets = {};
  final Map<String, ImageAssetLoadState> _states = {};
  String? _error;

  String? get error => _error;

  List<ImageAsset> getAssets(String section) => _sectionAssets[section] ?? [];
  
  ImageAssetLoadState getState(String section) => 
      _states[section] ?? ImageAssetLoadState.idle;

  Future<void> loadAssets(String section) async {
    _states[section] = ImageAssetLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      final assets = await ImageAssetService.getAssetsBySection(section);
      _sectionAssets[section] = assets;
      _states[section] = ImageAssetLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _states[section] = ImageAssetLoadState.error;
    }
    notifyListeners();
  }

  ImageAsset? getFeaturedAsset(String section) {
    final assets = getAssets(section);
    if (assets.isEmpty) return null;
    // Return the first active asset (they are already sorted by displayOrder in backend)
    return assets.first;
  }
}
