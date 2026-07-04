import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<({double latitude, double longitude})?> geocodeAddress(
    String address,
  ) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return null;

    try {
      final results = await locationFromAddress(trimmed);
      if (results.isEmpty) return null;
      final location = results.first;
      return (
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  Future<({double latitude, double longitude})?> resolveDestination({
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    if (latitude != null && longitude != null) {
      return (latitude: latitude, longitude: longitude);
    }
    return geocodeAddress(address);
  }

  double distanceInKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    final meters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return meters / 1000;
  }

  String formatDistanceKm(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  String formatPlacemark(Placemark placemark) {
    final parts = <String>[
      if (placemark.street?.trim().isNotEmpty == true) placemark.street!.trim(),
      if (placemark.subLocality?.trim().isNotEmpty == true)
        placemark.subLocality!.trim(),
      if (placemark.locality?.trim().isNotEmpty == true)
        placemark.locality!.trim(),
      if (placemark.administrativeArea?.trim().isNotEmpty == true)
        placemark.administrativeArea!.trim(),
      if (placemark.postalCode?.trim().isNotEmpty == true)
        placemark.postalCode!.trim(),
      if (placemark.country?.trim().isNotEmpty == true) placemark.country!.trim(),
    ];

    return parts.join(', ');
  }

  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;
      final formatted = formatPlacemark(placemarks.first);
      return formatted.isEmpty ? null : formatted;
    } catch (_) {
      return null;
    }
  }
}
