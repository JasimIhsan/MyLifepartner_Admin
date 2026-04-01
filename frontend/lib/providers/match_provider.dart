import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/services/match_service.dart';
import 'package:mylifepartner/utils/dio_error_helper.dart';

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

  List<MatchRecommendation> _sentInterests = [];
  List<MatchRecommendation> _receivedInterests = [];
  List<MatchRecommendation> _mutualMatches = [];

  List<MatchRecommendation> get sentInterests => _sentInterests;
  List<MatchRecommendation> get receivedInterests => _receivedInterests;
  List<MatchRecommendation> get mutualMatches => _mutualMatches;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadRecommendations() async {
    _state = MatchLoadState.loading;
    _error = null;
    _currentIndex = 0;
    notifyListeners();

    try {
      final results = await MatchService.getRecommendations();
      _profiles = results;
      _state = MatchLoadState.loaded;
    } on DioException catch (e) {
      _error = getDioErrorMessage(
        e,
        fallback: 'Failed to load recommendations',
      );
      _state = MatchLoadState.error;
    } catch (e) {
      _error = 'An unexpected error occurred: ${e.toString()}';
      _state = MatchLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadSentInterests() async {
    _state = MatchLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      final results = await MatchService.getSentInterests();
      _sentInterests = results;
      _state = MatchLoadState.loaded;
    } on DioException catch (e) {
      _error = getDioErrorMessage(e, fallback: 'Failed to load sent interests');
      _state = MatchLoadState.error;
    } catch (e) {
      _error = 'An unexpected error occurred: ${e.toString()}';
      _state = MatchLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadReceivedInterests() async {
    _state = MatchLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      final results = await MatchService.getReceivedInterests();
      _receivedInterests = results;
      _state = MatchLoadState.loaded;
    } on DioException catch (e) {
      _error = getDioErrorMessage(
        e,
        fallback: 'Failed to load received interests',
      );
      _state = MatchLoadState.error;
    } catch (e) {
      _error = 'An unexpected error occurred: ${e.toString()}';
      _state = MatchLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadMutualMatches() async {
    _state = MatchLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      final results = await MatchService.getMutualMatches();
      _mutualMatches = results;
      _state = MatchLoadState.loaded;
    } on DioException catch (e) {
      _error = getDioErrorMessage(e, fallback: 'Failed to load mutual matches');
      _state = MatchLoadState.error;
    } catch (e) {
      _error = 'An unexpected error occurred: ${e.toString()}';
      _state = MatchLoadState.error;
    }
    notifyListeners();
  }

  Future<void> swipeLeft({int? targetProfileId}) async {
    final id = targetProfileId ?? (hasProfiles ? _profiles[_currentIndex].id : null);
    if (id == null) return;
    try {
      await MatchService.swipe(targetProfileId: id, action: 'LEFT');
      if (targetProfileId == null) {
        _advanceIndex();
      } else {
        _removeProfile(id);
      }
    } on DioException catch (e) {
      _error = getDioErrorMessage(e, fallback: 'Failed to record skip');
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'An unexpected error occurred during swipe';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> swipeRight({int? targetProfileId}) async {
    final id = targetProfileId ?? (hasProfiles ? _profiles[_currentIndex].id : null);
    if (id == null) return;
    try {
      await MatchService.swipe(targetProfileId: id, action: 'RIGHT');
      if (targetProfileId == null) {
        _advanceIndex();
      } else {
        _removeProfile(id);
      }
    } on DioException catch (e) {
      _error = getDioErrorMessage(e, fallback: 'Failed to send interest');
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'An unexpected error occurred during interest';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> swipeUp({int? targetProfileId}) async {
    final id = targetProfileId ?? (hasProfiles ? _profiles[_currentIndex].id : null);
    if (id == null) return;
    try {
      await MatchService.swipe(targetProfileId: id, action: 'UP');
      if (targetProfileId == null) {
        _advanceIndex();
      } else {
        _removeProfile(id);
      }
    } on DioException catch (e) {
      _error = getDioErrorMessage(e, fallback: 'Failed to skip profile');
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'An unexpected error occurred during skip';
      notifyListeners();
      rethrow;
    }
  }

  void _removeProfile(int id) {
    final idx = _profiles.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _profiles.removeAt(idx);
      if (_currentIndex >= _profiles.length) {
        _currentIndex = 0;
        if (_profiles.isEmpty) {
          loadRecommendations();
          return;
        }
      }
      notifyListeners();
    }
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
