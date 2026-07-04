import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mechfixes/core/config/google_maps_config.dart';

class DrivingRouteResult {
  const DrivingRouteResult({
    required this.distanceText,
    required this.routePoints,
  });

  final String distanceText;
  final List<LatLng> routePoints;
}

/// Fetches driving routes from the Google Maps Directions API.
class DirectionsService {
  DirectionsService({http.Client? client, PolylinePoints? polylinePoints})
      : _client = client ?? http.Client(),
        _polylinePoints = polylinePoints ?? PolylinePoints();

  final http.Client _client;
  final PolylinePoints _polylinePoints;

  Future<DrivingRouteResult?> fetchDrivingRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    final uri = Uri.parse(GoogleMapsConfig.directionsBaseUrl).replace(
      queryParameters: {
        'origin': '$originLatitude,$originLongitude',
        'destination': '$destinationLatitude,$destinationLongitude',
        'key': GoogleMapsConfig.apiKey,
      },
    );

    try {
      debugPrint('[DirectionsService] GET $uri');
      final response = await _client.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        debugPrint(
          '[DirectionsService] HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;

      final status = body['status']?.toString();
      if (status != 'OK') {
        debugPrint('[DirectionsService] API status: $status');
        return null;
      }

      final routes = body['routes'];
      if (routes is! List || routes.isEmpty) return null;

      final route = routes.first;
      if (route is! Map<String, dynamic>) return null;

      final legs = route['legs'];
      if (legs is! List || legs.isEmpty) return null;

      final leg = legs.first;
      if (leg is! Map<String, dynamic>) return null;

      final distance = leg['distance'];
      if (distance is! Map<String, dynamic>) return null;

      final distanceText = distance['text']?.toString().trim();
      if (distanceText == null || distanceText.isEmpty) return null;

      final overviewPolyline = route['overview_polyline'];
      if (overviewPolyline is! Map<String, dynamic>) return null;

      final encodedPoints = overviewPolyline['points']?.toString();
      if (encodedPoints == null || encodedPoints.isEmpty) return null;

      final decoded = _polylinePoints.decodePolyline(encodedPoints);
      final routePoints = decoded
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList(growable: false);

      if (routePoints.isEmpty) return null;

      return DrivingRouteResult(
        distanceText: distanceText,
        routePoints: routePoints,
      );
    } catch (error, stackTrace) {
      debugPrint('[DirectionsService] Failed to fetch route: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  void dispose() => _client.close();
}
