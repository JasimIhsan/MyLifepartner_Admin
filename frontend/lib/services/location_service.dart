import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum CurrentLocationStatus {
  initial,
  checkingPermission,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  fetchingCoordinates,
  reverseGeocoding,
  success,
  failed,
}

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Future<CurrentLocationStatus> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return CurrentLocationStatus.success;
    }
    if (permission == LocationPermission.deniedForever) {
      return CurrentLocationStatus.permissionDeniedForever;
    }
    return CurrentLocationStatus.permissionDenied;
  }

  Future<CurrentLocationStatus> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return CurrentLocationStatus.success;
    }
    if (permission == LocationPermission.deniedForever) {
      return CurrentLocationStatus.permissionDeniedForever;
    }
    return CurrentLocationStatus.permissionDenied;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<Position> getCurrentPosition() async {
    try {
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null &&
          DateTime.now().difference(lastPosition.timestamp).inMinutes < 60) {
        return lastPosition;
      }
    } catch (_) {
      // Ignore errors fetching last known position
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Future<void> openAppSettings() async {
    if (!kIsWeb) {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> openLocationSettings() async {
    if (!kIsWeb) {
      await Geolocator.openLocationSettings();
    }
  }
}

