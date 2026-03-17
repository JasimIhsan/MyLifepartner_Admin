import 'package:flutter/foundation.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/services/match_service.dart';

enum MatchLoadState { idle, loading, loaded, error }

// ── Dummy data for UI testing ─────────────────────────────────────────────────
final _dummyProfiles = [
  MatchRecommendation(
    id: 1,
    name: 'Aisha Rahman',
    age: 27,
    heightCm: 163,
    city: 'Karachi',
    religion: 'Islam',
    occupation: 'Software Engineer',
    matchPercentage: 92,
    compatibilityHighlights: [
      'Family-oriented',
      'Love for travel',
      'Similar values',
    ],
    images: [
      MatchImage(
        imageUrl:
            'https://images.unsplash.com/photo-1609505848912-b7c3b8b4beda?q=80&w=765&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        isPrimary: true,
      ),
    ],
  ),
  MatchRecommendation(
    id: 2,
    name: 'Sana Malik',
    age: 25,
    heightCm: 158,
    city: 'Lahore',
    religion: 'Islam',
    occupation: 'Doctor',
    matchPercentage: 87,
    compatibilityHighlights: [
      'Loves cooking',
      'Fitness enthusiast',
      'Career-driven',
    ],
    images: [
      MatchImage(
        imageUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8N3x8Z2lybHxlbnwwfHwwfHx8MA%3D%3D',
        isPrimary: true,
      ),
    ],
  ),
  MatchRecommendation(
    id: 3,
    name: 'Fatima Zahra',
    age: 29,
    heightCm: 165,
    city: 'Islamabad',
    religion: 'Islam',
    occupation: 'Teacher',
    matchPercentage: 81,
    compatibilityHighlights: ['Book lover', 'Kind-hearted', 'Strong deen'],
    images: [
      MatchImage(
        imageUrl:
            'https://images.unsplash.com/photo-1589571894960-20bbe2828d0a?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NDN8fGdpcmx8ZW58MHx8MHx8fDA%3D',
        isPrimary: true,
      ),
    ],
  ),
  MatchRecommendation(
    id: 4,
    name: 'Nadia Khan',
    age: 26,
    heightCm: 160,
    city: 'Peshawar',
    religion: 'Islam',
    occupation: 'Graphic Designer',
    matchPercentage: 76,
    compatibilityHighlights: ['Creative', 'Down to earth', 'Family values'],
    images: [
      MatchImage(
        imageUrl:
            'https://images.unsplash.com/photo-1604004215402-e0be233f39be?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NDZ8fGdpcmx8ZW58MHx8MHx8fDA%3D',
        isPrimary: true,
      ),
    ],
  ),
  MatchRecommendation(
    id: 5,
    name: 'Mariam Siddiqui',
    age: 28,
    heightCm: 162,
    city: 'Dubai',
    religion: 'Islam',
    occupation: 'Accountant',
    matchPercentage: 73,
    compatibilityHighlights: ['Ambitious', 'Travel lover', 'Respectful'],
    images: [
      MatchImage(
        imageUrl:
            'https://plus.unsplash.com/premium_photo-1673792686134-f8cbeb0ad3e3?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        isPrimary: true,
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

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

    // Keep the real API call so it still fires correctly in production.
    // For now we discard the result and load dummy data instead for UI testing.
    try {
      await MatchService.getRecommendations();
    } catch (_) {
      // Swallow errors during testing phase — dummy data will still load.
    }

    _profiles = List<MatchRecommendation>.from(_dummyProfiles);
    _state = MatchLoadState.loaded;
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
      loadRecommendations();
    } else {
      notifyListeners();
    }
  }
}
