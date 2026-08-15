import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:life_partner_again/models/discovery_filter.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/services/discovery_service.dart';
import 'package:life_partner_again/utils/dio_error_helper.dart';

enum DiscoveryState { idle, loading, loaded, error }

class DiscoveryProvider extends ChangeNotifier {
  List<MatchRecommendation> _profiles = [];
  DiscoveryState _state = DiscoveryState.idle;
  String? _error;

  DiscoveryFilter _filter = DiscoveryFilter();

  int _page = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;
  int _totalCount = 0;

  // Track requests to prevent race conditions
  int _fetchRequestId = 0;

  List<MatchRecommendation> get profiles => _profiles;
  DiscoveryState get state => _state;
  String? get error => _error;
  DiscoveryFilter get filter => _filter;
  bool get hasNextPage => _hasNextPage;
  bool get isLoadingMore => _isLoadingMore;
  int get totalCount => _totalCount;

  void applyFilter(DiscoveryFilter newFilter) {
    _filter = newFilter;
    refresh(clearProfiles: true);
  }

  void resetFilter() {
    _filter = DiscoveryFilter();
    refresh(clearProfiles: true);
  }

  Future<void> refresh({bool clearProfiles = true}) async {
    _fetchRequestId++; // Invalidate previous requests
    final currentRequestId = _fetchRequestId;

    _page = 1;
    _hasNextPage = true;
    if (clearProfiles) {
      _profiles = [];
    }
    _state = DiscoveryState.loading;
    _error = null;
    notifyListeners();

    await _fetchData(requestId: currentRequestId, isLoadMore: false);
  }

  Future<void> loadMore() async {
    if (!_hasNextPage || _isLoadingMore || _state == DiscoveryState.loading) {
      return;
    }

    _fetchRequestId++; // Invalidate previous requests
    final currentRequestId = _fetchRequestId;

    _isLoadingMore = true;
    _page++;
    notifyListeners();

    await _fetchData(requestId: currentRequestId, isLoadMore: true);
  }

  Future<void> _fetchData({
    required int requestId,
    bool isLoadMore = false,
  }) async {
    try {
      final result = await DiscoveryService.discoverProfiles(
        filter: _filter,
        page: _page,
      );

      // If a new request was started, discard this response
      if (_fetchRequestId != requestId) return;

      final fetchedProfiles = result['profiles'] as List<MatchRecommendation>;

      if (isLoadMore) {
        // Prevent duplicate profiles
        final uniqueNewProfiles = fetchedProfiles
            .where(
              (newProfile) =>
                  !_profiles.any((existing) => existing.id == newProfile.id),
            )
            .toList();
        _profiles.addAll(uniqueNewProfiles);
      } else {
        _profiles = fetchedProfiles;
      }

      _hasNextPage = result['hasNextPage'] as bool;
      _totalCount = result['total'] as int;
      _state = DiscoveryState.loaded;
    } on DioException catch (e) {
      if (_fetchRequestId != requestId) return;

      _error = getDioErrorMessage(e, fallback: 'Failed to load profiles');
      _state = DiscoveryState.error;
      // If we failed to load more, revert the page increment
      if (isLoadMore) _page--;
    } catch (e) {
      if (_fetchRequestId != requestId) return;

      _error = e.toString().replaceAll('Exception: ', '');
      _state = DiscoveryState.error;
      if (isLoadMore) _page--;
    } finally {
      if (_fetchRequestId == requestId) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }
}
