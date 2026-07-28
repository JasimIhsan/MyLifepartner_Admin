import 'dart:async';

import 'package:flutter/material.dart';
import 'package:life_partner_again/models/location_details.dart';
import 'package:life_partner_again/models/location_prediction.dart';
import 'package:life_partner_again/services/location_api_service.dart';
import 'package:life_partner_again/services/location_service.dart';
import 'package:uuid/uuid.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final Uuid _uuid = const Uuid();

  String _sessionToken = const Uuid().v4();

  LocationDetails? _selectedCountry;
  LocationDetails? _selectedState;
  LocationDetails? _selectedCity;

  List<LocationPrediction> _countrySuggestions = [];
  List<LocationPrediction> _stateSuggestions = [];
  List<LocationPrediction> _citySuggestions = [];

  bool _isSearchingCountry = false;
  bool _isSearchingState = false;
  bool _isSearchingCity = false;
  bool _isLoadingPlaceDetails = false;

  CurrentLocationStatus _currentLocationStatus = CurrentLocationStatus.initial;
  String? _currentLocationError;

  String? _countryError;
  String? _stateError;
  String? _cityError;

  bool _hasUserManuallyEditedLocation = false;
  bool _hasAttemptedInitialLocationDetection = false;

  Timer? _debounceTimer;

  // Getters
  LocationDetails? get selectedCountry => _selectedCountry;
  LocationDetails? get selectedState => _selectedState;
  LocationDetails? get selectedCity => _selectedCity;
  List<LocationPrediction> get countrySuggestions => _countrySuggestions;
  List<LocationPrediction> get stateSuggestions => _stateSuggestions;
  List<LocationPrediction> get citySuggestions => _citySuggestions;
  bool get isSearchingCountry => _isSearchingCountry;
  bool get isSearchingState => _isSearchingState;
  bool get isSearchingCity => _isSearchingCity;
  bool get isLoadingPlaceDetails => _isLoadingPlaceDetails;
  CurrentLocationStatus get currentLocationStatus => _currentLocationStatus;
  String? get currentLocationError => _currentLocationError;
  String? get countryError => _countryError;
  String? get stateError => _stateError;
  String? get cityError => _cityError;
  bool get hasUserManuallyEditedLocation => _hasUserManuallyEditedLocation;
  bool get hasAttemptedInitialLocationDetection =>
      _hasAttemptedInitialLocationDetection;

  // Session Token
  void _generateNewSessionToken() {
    _sessionToken = _uuid.v4();
  }

  // --- Current Location Logic ---

  Future<void> detectAndFillCurrentLocation({bool forceReplace = false}) async {
    if (_currentLocationStatus == CurrentLocationStatus.fetchingCoordinates ||
        _currentLocationStatus == CurrentLocationStatus.reverseGeocoding ||
        _currentLocationStatus == CurrentLocationStatus.checkingPermission) {
      return; // Prevent duplicate simultaneous calls
    }

    _currentLocationError = null;
    _currentLocationStatus = CurrentLocationStatus.checkingPermission;
    notifyListeners();

    try {
      final isEnabled = await _locationService.isLocationServiceEnabled();
      if (!isEnabled) {
        _currentLocationStatus = CurrentLocationStatus.serviceDisabled;
        _currentLocationError = "Location services are disabled.";
        notifyListeners();
        return;
      }

      var permission = await _locationService.checkPermission();
      if (permission == CurrentLocationStatus.permissionDenied) {
        permission = await _locationService.requestPermission();
      }

      if (permission == CurrentLocationStatus.permissionDeniedForever) {
        _currentLocationStatus = CurrentLocationStatus.permissionDeniedForever;
        _currentLocationError = "Location permission permanently denied.";
        notifyListeners();
        return;
      } else if (permission != CurrentLocationStatus.success) {
        _currentLocationStatus = CurrentLocationStatus.permissionDenied;
        _currentLocationError = "Location permission denied.";
        notifyListeners();
        return;
      }

      _currentLocationStatus = CurrentLocationStatus.fetchingCoordinates;
      notifyListeners();

      final position = await _locationService.getCurrentPosition();

      _currentLocationStatus = CurrentLocationStatus.reverseGeocoding;
      notifyListeners();

      final details = await LocationApiService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (details != null) {
        if (!forceReplace) {
          // If not forcing replace and user has edited, don't overwrite
          if (_hasUserManuallyEditedLocation) {
            _currentLocationStatus = CurrentLocationStatus.success;
            notifyListeners();
            return;
          }
          // Do not replace already valid complete selection
          if (_selectedCountry != null && _selectedCity != null) {
            _currentLocationStatus = CurrentLocationStatus.success;
            notifyListeners();
            return;
          }
        }

        if (details.country != null) {
          _selectedCountry = LocationDetails(
            placeId: details.placeId,
            name: details.country!,
            formattedAddress: details.country!,
            countryCode: details.countryCode,
            types: ['country'],
            source: 'current_location',
          );
        }

        if (details.state != null) {
          _selectedState = LocationDetails(
            placeId: details.placeId,
            name: details.state!,
            formattedAddress: '${details.state}, ${details.country}',
            countryCode: details.countryCode,
            stateCode: details.stateCode,
            types: ['administrative_area_level_1'],
            source: 'current_location',
          );
        }

        if (details.city != null) {
          _selectedCity = LocationDetails(
            placeId: details.placeId,
            name: details.city!,
            formattedAddress: details.formattedAddress,
            countryCode: details.countryCode,
            stateCode: details.stateCode,
            latitude: position.latitude,
            longitude: position.longitude,
            types: details.types,
            source: 'current_location',
          );
        }

        _hasUserManuallyEditedLocation = false;
        _hasAttemptedInitialLocationDetection = true;
        _currentLocationStatus = CurrentLocationStatus.success;
      } else {
        _currentLocationStatus = CurrentLocationStatus.failed;
        _currentLocationError = "Failed to determine location details.";
      }
    } catch (e) {
      _currentLocationStatus = CurrentLocationStatus.failed;
      _currentLocationError = "Error detecting location: $e";
    }

    notifyListeners();
  }

  // --- Search Logic ---

  void searchCountry(String query) {
    if (query.length < 2) {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _countrySuggestions = [];
      notifyListeners();
      return;
    }

    _debounce(() async {
      _isSearchingCountry = true;
      notifyListeners();
      final results = await LocationApiService.searchLocations(
        query: query,
        type: 'country',
        sessionToken: _sessionToken,
      );
      _countrySuggestions = results;
      _isSearchingCountry = false;
      notifyListeners();
    });
  }

  void searchState(String query) {
    if (query.length < 2 || _selectedCountry?.countryCode == null) {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _stateSuggestions = [];
      notifyListeners();
      return;
    }

    _debounce(() async {
      _isSearchingState = true;
      notifyListeners();
      final results = await LocationApiService.searchLocations(
        query: query,
        type: 'state',
        sessionToken: _sessionToken,
        countryCode: _selectedCountry!.countryCode,
      );
      _stateSuggestions = results;
      _isSearchingState = false;
      notifyListeners();
    });
  }

  void searchCity(String query) {
    if (query.length < 2 ||
        _selectedCountry?.countryCode == null ||
        _selectedState?.name == null) {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _citySuggestions = [];
      notifyListeners();
      return;
    }

    _debounce(() async {
      _isSearchingCity = true;
      notifyListeners();
      final results = await LocationApiService.searchLocations(
        query: query,
        type: 'city',
        sessionToken: _sessionToken,
        countryCode: _selectedCountry!.countryCode,
        stateName: _selectedState!.name,
      );
      _citySuggestions = results;
      _isSearchingCity = false;
      notifyListeners();
    });
  }

  void _debounce(VoidCallback callback) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), callback);
  }

  // --- Selection Logic ---

  Future<void> selectCountry(LocationPrediction prediction) async {
    _isLoadingPlaceDetails = true;
    _countrySuggestions = [];
    notifyListeners();

    final details = await LocationApiService.getPlaceDetails(
      prediction.placeId,
    );
    if (details != null && details.types.contains('country')) {
      _selectedCountry = details;
      _selectedState = null;
      _selectedCity = null;
      _stateSuggestions = [];
      _citySuggestions = [];
      _hasUserManuallyEditedLocation = true;
      _countryError = null;
    } else {
      _countryError = "Invalid country selection.";
    }

    _generateNewSessionToken();
    _isLoadingPlaceDetails = false;
    notifyListeners();
  }

  Future<void> selectState(LocationPrediction prediction) async {
    _isLoadingPlaceDetails = true;
    _stateSuggestions = [];
    notifyListeners();

    final details = await LocationApiService.getPlaceDetails(
      prediction.placeId,
    );
    if (details != null &&
        details.countryCode == _selectedCountry?.countryCode) {
      _selectedState = details;
      _selectedCity = null;
      _citySuggestions = [];
      _hasUserManuallyEditedLocation = true;
      _stateError = null;
    } else {
      _stateError = "Invalid state selection.";
    }

    _generateNewSessionToken();
    _isLoadingPlaceDetails = false;
    notifyListeners();
  }

  Future<void> selectCity(LocationPrediction prediction) async {
    _isLoadingPlaceDetails = true;
    _citySuggestions = [];
    notifyListeners();

    final details = await LocationApiService.getPlaceDetails(
      prediction.placeId,
    );
    if (details != null &&
        details.countryCode == _selectedCountry?.countryCode) {
      final stateMatches =
          details.state?.toLowerCase() == _selectedState?.name.toLowerCase() ||
          details.stateCode?.toLowerCase() ==
              _selectedState?.stateCode?.toLowerCase();

      // If backend returns state properly, validate it.
      // Handle edge cases where state is not returned or countries have no states.
      if (_selectedState == null || stateMatches) {
        _selectedCity = details;
        _hasUserManuallyEditedLocation = true;
        _cityError = null;
      } else {
        _cityError = "The selected city does not belong to the selected state.";
      }
    } else {
      _cityError = "Invalid city selection.";
    }

    _generateNewSessionToken();
    _isLoadingPlaceDetails = false;
    notifyListeners();
  }

  // --- Manual clear/edit invalidation ---
  void invalidateCountry() {
    _selectedCountry = null;
    _selectedState = null;
    _selectedCity = null;
    notifyListeners();
  }

  void invalidateState() {
    _selectedState = null;
    _selectedCity = null;
    notifyListeners();
  }

  void invalidateCity() {
    _selectedCity = null;
    notifyListeners();
  }
}
