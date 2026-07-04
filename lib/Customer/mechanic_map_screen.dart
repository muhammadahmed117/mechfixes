import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mechfixes/core/config/google_maps_config.dart';
import 'package:mechfixes/services/directions_service.dart';
import 'package:mechfixes/services/location_service.dart';
import 'package:mechfixes/services/mechanics_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class MechanicMapScreen extends StatefulWidget {
  const MechanicMapScreen({
    super.key,
    required this.mechanicName,
    required this.address,
    this.latitude,
    this.longitude,
  });

  final String mechanicName;
  final String address;
  final double? latitude;
  final double? longitude;

  static Future<void> open(
    BuildContext context, {
    required String mechanicName,
    required String address,
    double? latitude,
    double? longitude,
  }) {
    if (address.trim().isEmpty && latitude == null && longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available for this mechanic'),
        ),
      );
      return Future.value();
    }

    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MechanicMapScreen(
          mechanicName: mechanicName,
          address: address,
          latitude: latitude,
          longitude: longitude,
        ),
      ),
    );
  }

  @override
  State<MechanicMapScreen> createState() => _MechanicMapScreenState();
}

class _MechanicMapScreenState extends State<MechanicMapScreen> {
  static const _primary = Color(0xFF1F3FAF);

  final LocationService _locationService = LocationService.instance;
  final DirectionsService _directionsService = DirectionsService();
  final MechanicsRepository _mechanicsRepository = MechanicsRepository.instance;

  GoogleMapController? _mapController;

  bool _isLoading = true;
  String? _errorMessage;
  String? _distanceLabel;
  LatLng? _userPosition;
  LatLng? _destination;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _directionsService.dispose();
    super.dispose();
  }

  Future<void> _loadMapData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final destination = await _locationService.resolveDestination(
        address: widget.address,
        latitude: widget.latitude,
        longitude: widget.longitude,
      );

      if (destination == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Could not find this mechanic on the map. Check the address.';
        });
        return;
      }

      final destLatLng = LatLng(
        destination.latitude,
        destination.longitude,
      );

      final userPosition = await _locationService.getCurrentPosition();
      LatLng? userLatLng;
      String? distanceLabel;
      final polylines = <Polyline>{};
      var routePoints = <LatLng>[];

      if (userPosition != null) {
        userLatLng = LatLng(userPosition.latitude, userPosition.longitude);

        final drivingRoute = await _directionsService.fetchDrivingRoute(
          originLatitude: userLatLng.latitude,
          originLongitude: userLatLng.longitude,
          destinationLatitude: destLatLng.latitude,
          destinationLongitude: destLatLng.longitude,
        );

        if (drivingRoute != null) {
          distanceLabel = drivingRoute.distanceText;
          routePoints = drivingRoute.routePoints;
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: routePoints,
              color: _primary,
              width: 4,
            ),
          );
        } else {
          debugPrint(
            '[MechanicMap] Directions API unavailable, using straight-line fallback',
          );
          final km = _locationService.distanceInKm(
            startLatitude: userLatLng.latitude,
            startLongitude: userLatLng.longitude,
            endLatitude: destLatLng.latitude,
            endLongitude: destLatLng.longitude,
          );
          distanceLabel = _locationService.formatDistanceKm(km);
          routePoints = [userLatLng, destLatLng];
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: routePoints,
              color: _primary.withValues(alpha: 0.6),
              width: 3,
            ),
          );
        }
      }

      final markers = await _buildMarkers(
        userLatLng: userLatLng,
        destination: destLatLng,
      );

      if (!mounted) return;
      setState(() {
        _destination = destLatLng;
        _userPosition = userLatLng;
        _distanceLabel = distanceLabel;
        _markers = markers;
        _polylines = polylines;
        _routePoints = routePoints;
        _isLoading = false;
      });

      await _fitCamera();
    } catch (error, stackTrace) {
      debugPrint('[MechanicMap] Failed to load map data: $error');
      debugPrint('$stackTrace');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load map. Please try again.';
      });
    }
  }

  Future<Set<Marker>> _buildMarkers({
    required LatLng destination,
    LatLng? userLatLng,
  }) async {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('selected_mechanic'),
        position: destination,
        infoWindow: InfoWindow(
          title: widget.mechanicName,
          snippet: widget.address.trim().isNotEmpty
              ? widget.address
              : 'Selected mechanic',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    if (userLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: userLatLng,
          infoWindow: const InfoWindow(title: 'Your location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );

      final nearbyMechanics = await _loadNearbyMechanicMarkers(
        userLatLng: userLatLng,
        selectedDestination: destination,
      );
      markers.addAll(nearbyMechanics);
    }

    return markers;
  }

  Future<Set<Marker>> _loadNearbyMechanicMarkers({
    required LatLng userLatLng,
    required LatLng selectedDestination,
  }) async {
    final markers = <Marker>{};

    try {
      final mechanics = await _mechanicsRepository.fetchVerifiedMechanics();
      var withinRadiusCount = 0;

      for (final mechanic in mechanics) {
        if (!mechanic.hasCoordinates) continue;

        final mechanicLat = mechanic.latitude!;
        final mechanicLng = mechanic.longitude!;
        final mechanicPosition = LatLng(mechanicLat, mechanicLng);

        final isSelectedDestination = _sameCoordinate(
          mechanicPosition,
          selectedDestination,
        );
        if (isSelectedDestination) continue;

        final distanceMeters = _locationService.distanceInMeters(
          startLatitude: userLatLng.latitude,
          startLongitude: userLatLng.longitude,
          endLatitude: mechanicLat,
          endLongitude: mechanicLng,
        );

        if (distanceMeters > GoogleMapsConfig.nearbyMechanicRadiusMeters) {
          continue;
        }

        withinRadiusCount++;
        markers.add(
          Marker(
            markerId: MarkerId('mechanic_${mechanic.uid}'),
            position: mechanicPosition,
            infoWindow: InfoWindow(
              title: mechanic.displayName,
              snippet: '${(distanceMeters / 1000).toStringAsFixed(1)} km away',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
          ),
        );
      }

      debugPrint(
        '[MechanicMap] Added $withinRadiusCount mechanic markers within '
        '${GoogleMapsConfig.nearbyMechanicRadiusMeters.toInt()} m',
      );
    } catch (error, stackTrace) {
      debugPrint('[MechanicMap] Failed to load nearby mechanic markers: $error');
      debugPrint('$stackTrace');
    }

    return markers;
  }

  bool _sameCoordinate(LatLng a, LatLng b) {
    const tolerance = 0.00001;
    return (a.latitude - b.latitude).abs() < tolerance &&
        (a.longitude - b.longitude).abs() < tolerance;
  }

  Future<void> _fitCamera() async {
    final controller = _mapController;
    final destination = _destination;
    if (controller == null || destination == null) return;

    final points = <LatLng>[
      if (_userPosition != null) _userPosition!,
      destination,
      ..._routePoints,
    ];

    if (points.length >= 2) {
      var minLat = points.first.latitude;
      var maxLat = points.first.latitude;
      var minLng = points.first.longitude;
      var maxLng = points.first.longitude;

      for (final point in points) {
        minLat = point.latitude < minLat ? point.latitude : minLat;
        maxLat = point.latitude > maxLat ? point.latitude : maxLat;
        minLng = point.longitude < minLng ? point.longitude : minLng;
        maxLng = point.longitude > maxLng ? point.longitude : maxLng;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: destination, zoom: 15),
      ),
    );
  }

  Future<void> _openExternalNavigation() async {
    final destination = _destination;
    if (destination == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open navigation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              color: _primary,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('Back', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Directions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  if (_destination != null)
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _destination!,
                        zoom: 14,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: _userPosition == null,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      onMapCreated: (controller) async {
                        _mapController = controller;
                        await _fitCamera();
                      },
                    )
                  else if (!_isLoading)
                    const Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 56,
                        color: Color(0xFF98A2B3),
                      ),
                    ),
                  if (_isLoading)
                    const ColoredBox(
                      color: Color(0x66FFFFFF),
                      child: Center(
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    ),
                  if (_errorMessage != null)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD0D5DD)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _BottomCard(
                      mechanicName: widget.mechanicName,
                      address: widget.address,
                      distanceLabel: _distanceLabel,
                      onStartNavigation: _destination == null
                          ? null
                          : _openExternalNavigation,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCard extends StatelessWidget {
  const _BottomCard({
    required this.mechanicName,
    required this.address,
    required this.distanceLabel,
    required this.onStartNavigation,
  });

  final String mechanicName;
  final String address;
  final String? distanceLabel;
  final VoidCallback? onStartNavigation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0D5DD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A101828),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mechanicName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF101828),
            ),
          ),
          if (address.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF667085),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF667085),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (distanceLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              'Driving distance: $distanceLabel',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F3FAF),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onStartNavigation,
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Start Navigation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F3FAF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
