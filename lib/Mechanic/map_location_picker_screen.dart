import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mechfixes/models/picked_location.dart';
import 'package:mechfixes/services/location_service.dart';
import 'package:mechfixes/core/localization/app_text.dart';
import 'package:mechfixes/core/localization/language_toggle_button.dart';

class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({super.key, this.initialPosition});

  final LatLng? initialPosition;

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  static const _primary = Color(0xFF1F3FAF);
  static const _fallbackPosition = LatLng(32.4935, 74.5229);

  final LocationService _locationService = LocationService.instance;

  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  bool _isLoading = true;
  bool _isConfirming = false;
  String? _previewAddress;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    LatLng startPosition = widget.initialPosition ?? _fallbackPosition;

    if (widget.initialPosition == null) {
      final currentPosition = await _locationService.getCurrentPosition();
      if (currentPosition != null) {
        startPosition = LatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _selectedPosition = startPosition;
      _isLoading = false;
    });

    await _updatePreviewAddress(startPosition);
  }

  Future<void> _updatePreviewAddress(LatLng position) async {
    final address = await _locationService.reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (!mounted) return;
    setState(() {
      _previewAddress = address;
    });
  }

  void _onCameraIdle() {
    final position = _selectedPosition;
    if (position == null) return;
    _updatePreviewAddress(position);
  }

  Future<void> _confirmLocation() async {
    final position = _selectedPosition;
    if (position == null || _isConfirming) return;

    setState(() => _isConfirming = true);

    try {
      final address = await _locationService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        PickedLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address:
              address ??
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  Future<void> _moveToCurrentLocation() async {
    final currentPosition = await _locationService.getCurrentPosition();
    if (currentPosition == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppText.of(
              context,
              english: 'Unable to access your current location',
              romanUrdu: 'Aap ki current location access nahi ho saki',
            ),
          ),
        ),
      );
      return;
    }

    final target = LatLng(currentPosition.latitude, currentPosition.longitude);
    setState(() => _selectedPosition = target);
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 16)),
    );
    await _updatePreviewAddress(target);
  }

  @override
  Widget build(BuildContext context) {
    final selectedPosition = _selectedPosition;

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
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          AppText.of(
                            context,
                            english: 'Back',
                            romanUrdu: 'Wapas',
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppText.of(
                      context,
                      english: 'Select Location',
                      romanUrdu: 'Location Select Karein',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const LanguageToggleButton(compact: true),
                  IconButton(
                    onPressed: _isLoading ? null : _moveToCurrentLocation,
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    tooltip: AppText.of(
                      context,
                      english: 'My location',
                      romanUrdu: 'Meri location',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (selectedPosition != null)
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: selectedPosition,
                        zoom: 16,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      onMapCreated: (controller) => _mapController = controller,
                      onCameraMove: (position) {
                        setState(() => _selectedPosition = position.target);
                      },
                      onCameraIdle: _onCameraIdle,
                      onTap: (position) {
                        setState(() => _selectedPosition = position);
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(position),
                        );
                        _updatePreviewAddress(position);
                      },
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(color: _primary),
                    ),
                  if (!_isLoading)
                    IgnorePointer(
                      child: Icon(
                        Icons.location_on,
                        size: 42,
                        color: Colors.red.shade700,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  if (_isLoading)
                    const ColoredBox(
                      color: Color(0x66FFFFFF),
                      child: Center(
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Container(
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
                            AppText.of(
                              context,
                              english: 'Move the map or tap to place the pin',
                              romanUrdu:
                                  'Map hilayein ya pin lagane ke liye tap karein',
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF101828),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _previewAddress ??
                                AppText.of(
                                  context,
                                  english: 'Fetching address...',
                                  romanUrdu: 'Pata la rahe hain...',
                                ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF667085),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed:
                                  _isConfirming || selectedPosition == null
                                  ? null
                                  : _confirmLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isConfirming
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      AppText.of(
                                        context,
                                        english: 'Confirm Location',
                                        romanUrdu: 'Location Confirm Karein',
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
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
