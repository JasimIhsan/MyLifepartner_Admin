import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return CurrentLocationStatus.success;
    if (status.isPermanentlyDenied) {
      return CurrentLocationStatus.permissionDeniedForever;
    }
    return CurrentLocationStatus.permissionDenied;
  }

  Future<CurrentLocationStatus> requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) return CurrentLocationStatus.success;
    if (status.isPermanentlyDenied) {
      return CurrentLocationStatus.permissionDeniedForever;
    }
    return CurrentLocationStatus.permissionDenied;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
