import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PickedLocation {
  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;

  LatLng get latLng => LatLng(latitude, longitude);

  GeoPoint toGeoPoint() => GeoPoint(latitude, longitude);

  Map<String, dynamic> toFirestoreFields() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'geoPoint': toGeoPoint(),
    };
  }
}
