/// Google Maps Platform credentials and map-related constants.
class GoogleMapsConfig {
  GoogleMapsConfig._();

  static const String apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  static const String directionsBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  /// Mechanics within this radius (meters) are shown on the map.
  static const double nearbyMechanicRadiusMeters = 5000;
}
