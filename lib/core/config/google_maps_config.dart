/// Google Maps Platform credentials and map-related constants.
class GoogleMapsConfig {
  GoogleMapsConfig._();

  static const String apiKey = 'AIzaSyC6boLtcXo9iJY2dJzmK5JtFd7paG0pPkA';

  static const String directionsBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  /// Mechanics within this radius (meters) are shown on the map.
  static const double nearbyMechanicRadiusMeters = 5000;
}
