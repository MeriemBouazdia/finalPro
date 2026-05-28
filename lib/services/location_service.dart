import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/errors/app_exception.dart';
import '../models/farm_location.dart';

/// Handles device GPS acquisition and reverse-geocoding.
/// All platform-specific errors are converted to [AppException].
class LocationService {
  /// Requests location permission if needed, then returns the device's current
  /// position as a [FarmLocation] with a human-readable name.
  Future<FarmLocation> detectCurrentLocation() async {
    await _ensureServiceEnabled();
    await _ensurePermissionGranted();

    final position = await _getCurrentPosition();
    final name = await _resolveAddressName(position);

    return FarmLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      locationName: name,
    );
  }

  //  Private helpers

  Future<void> _ensureServiceEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const AppException(
        'Location services are disabled. Please enable them.',
      );
    }
  }

  Future<void> _ensurePermissionGranted() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const AppException(
          'Location permission is required to detect your location.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const AppException(
        'Location permission is permanently denied. '
        'Please enable it in app settings.',
      );
    }
  }

  Future<Position> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      throw AppException('Failed to get current position: $e');
    }
  }

  Future<String> _resolveAddressName(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return 'Unknown Location';

      final place = placemarks.first;
      final parts = <String>[
        if (place.locality?.isNotEmpty == true) place.locality!,
        if (place.administrativeArea?.isNotEmpty == true)
          place.administrativeArea!,
        if (place.country?.isNotEmpty == true) place.country!,
      ];

      return parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
    } catch (_) {
      // Geocoding failure is non-fatal — fall back to coordinates label.
      return '${position.latitude.toStringAsFixed(4)}, '
          '${position.longitude.toStringAsFixed(4)}';
    }
  }
}
