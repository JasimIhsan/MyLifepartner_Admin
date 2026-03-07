import 'package:flutter/foundation.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/services/match_service.dart';

enum MatchLoadState { idle, loading, loaded, error }

class MatchProvider extends ChangeNotifier {
  List<MatchRecommendation> _profiles = [];
  MatchLoadState _state = MatchLoadState.idle;
  String? _error;
  int _currentIndex = 0;

  List<MatchRecommendation> get profiles => _profiles;
  MatchLoadState get state => _state;
  String? get error => _error;
  int get currentIndex => _currentIndex;

  bool get hasProfiles =>
      _profiles.isNotEmpty && _currentIndex < _profiles.length;
  MatchRecommendation? get currentProfile =>
      hasProfiles ? _profiles[_currentIndex] : null;

  Future<void> loadRecommendations() async {
    _state = MatchLoadState.loading;
    _error = null;
    _currentIndex = 0;
    notifyListeners();

    try {
      _profiles = await MatchService.getRecommendations();
      _state = MatchLoadState.loaded;
    } catch (e) {
      _state = MatchLoadState.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> swipeLeft() async {
    if (!hasProfiles) return;
    final profile = _profiles[_currentIndex];
    await MatchService.swipe(targetProfileId: profile.id, action: 'LEFT');
    _advanceIndex();
  }

  Future<void> swipeRight() async {
    if (!hasProfiles) return;
    final profile = _profiles[_currentIndex];
    await MatchService.swipe(targetProfileId: profile.id, action: 'RIGHT');
    _advanceIndex();
  }

  Future<void> swipeUp() async {
    if (!hasProfiles) return;
    final profile = _profiles[_currentIndex];
    await MatchService.swipe(targetProfileId: profile.id, action: 'UP');
    _advanceIndex();
  }

  void _advanceIndex() {
    _currentIndex++;
    if (_currentIndex >= _profiles.length) {
      // Reload when exhausted
      loadRecommendations();
    } else {
      notifyListeners();
    }
  }
}
