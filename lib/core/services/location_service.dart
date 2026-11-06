import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../error/app_exception.dart';

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

final locationServiceProvider = Provider<LocationService>((ref) => const LocationService());

class LocationService {
  const LocationService();

  /// Current GPS position, asking for permission when needed.
  Future<GeoPoint> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AppException('Turn on location (GPS) so we can confirm you are at the hostel.', code: 'location_off');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const AppException('Location permission is needed to mark attendance.', code: 'location_denied');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AppException(
        'Location is blocked for this app. Allow it in your phone settings, then try again.',
        code: 'location_blocked',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } on Object {
      throw const AppException("We couldn't get your location. Step outside or near a window and try again.",
          code: 'location_failed');
    }
  }

  Future<bool> openSettings() => Geolocator.openAppSettings();
}
