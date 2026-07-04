import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mechfixes/Mechanic/mechanic_profile_data.dart';
import 'package:mechfixes/Mechanic/mechanic_specialty_config.dart';
import 'package:mechfixes/Mechanic/mechanic_dashboard_screen.dart';
import 'package:mechfixes/Mechanic/map_location_picker_screen.dart';
import 'package:mechfixes/models/picked_location.dart';

class MechanicProfileEditScreen extends StatefulWidget {
  const MechanicProfileEditScreen({
    super.key,
    this.initialEmail = "eliteauto@example.com",
    this.initialShopName = '',
    this.initialPhone = '',
    this.initialAddress = '',
    this.initialSpecialty = '',
    this.initialSpecialties = const [],
    this.initialSpecialtyServices = const {},
    this.initialOpeningDays = '',
    this.initialOpeningHours = '',
    this.initialPhotoBytes,
    this.initialPhotoScale = 1.0,
    this.initialPhotoAlignmentX = 0.0,
    this.initialPhotoAlignmentY = 0.0,
    this.isOnboarding = false,
  });

  final String initialEmail;
  final String initialShopName;
  final String initialPhone;
  final String initialAddress;
  final String initialSpecialty;
  final List<String> initialSpecialties;
  final Map<String, List<String>> initialSpecialtyServices;
  final String initialOpeningDays;
  final String initialOpeningHours;
  final Uint8List? initialPhotoBytes;
  final double initialPhotoScale;
  final double initialPhotoAlignmentX;
  final double initialPhotoAlignmentY;
  final bool isOnboarding;

  @override
  State<MechanicProfileEditScreen> createState() =>
      _MechanicProfileEditScreenState();
}

class _MechanicProfileEditScreenState extends State<MechanicProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  static const List<String> _specialtyOptions = MechanicSpecialtyConfig.options;

  late final TextEditingController shopNameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController addressController;
  late final TextEditingController openingDayStartController;
  late final TextEditingController openingDayEndController;
  late final TextEditingController openingHourStartController;
  late final TextEditingController openingHourEndController;
  final List<String> selectedSpecialties = [];
  final Map<String, List<String>> specialtyServices = {};
  final Map<String, TextEditingController> _serviceInputControllers = {};
  final Map<String, String?> _serviceInputErrors = {};
  String? specialtyValidationError;
  Uint8List? selectedPhotoBytes;
  double photoScale = 1.0;
  double photoAlignmentX = 0.0;
  double photoAlignmentY = 0.0;
  double _gestureStartScale = 1.0;
  bool _isSaving = false;
  bool _isLoadingProfile = false;
  double? _selectedLatitude;
  double? _selectedLongitude;

  (String start, String end) _splitRange(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return ('', '');

    if (trimmed.contains(' - ')) {
      final parts = trimmed.split(' - ');
      if (parts.length >= 2) {
        return (parts.first.trim(), parts.sublist(1).join(' - ').trim());
      }
    }

    if (trimmed.contains('-')) {
      final parts = trimmed.split('-');
      if (parts.length >= 2) {
        return (parts.first.trim(), parts.sublist(1).join('-').trim());
      }
    }

    return (trimmed, '');
  }

  String get _combinedOpeningDays =>
      '${openingDayStartController.text.trim()}-${openingDayEndController.text.trim()}';

  String get _combinedOpeningHours =>
      '${openingHourStartController.text.trim()} - ${openingHourEndController.text.trim()}';

  @override
  void initState() {
    super.initState();
    shopNameController = TextEditingController(text: widget.initialShopName);
    phoneController = TextEditingController(text: widget.initialPhone);
    emailController = TextEditingController(text: widget.initialEmail);
    addressController = TextEditingController(text: widget.initialAddress);

    final dayRange = _splitRange(widget.initialOpeningDays);
    final hourRange = _splitRange(widget.initialOpeningHours);
    openingDayStartController = TextEditingController(text: dayRange.$1);
    openingDayEndController = TextEditingController(text: dayRange.$2);
    openingHourStartController = TextEditingController(text: hourRange.$1);
    openingHourEndController = TextEditingController(text: hourRange.$2);

    if (widget.initialSpecialties.isNotEmpty) {
      selectedSpecialties.addAll(widget.initialSpecialties);
    } else if (widget.initialSpecialty.isNotEmpty) {
      selectedSpecialties.add(widget.initialSpecialty);
    }

    for (final specialty in selectedSpecialties) {
      specialtyServices[specialty] =
          List<String>.from(widget.initialSpecialtyServices[specialty] ?? const []);
      _serviceInputControllers[specialty] = TextEditingController();
    }

    selectedPhotoBytes = widget.initialPhotoBytes;
    photoScale = widget.initialPhotoScale;
    photoAlignmentX = widget.initialPhotoAlignmentX;
    photoAlignmentY = widget.initialPhotoAlignmentY;

    if (!widget.isOnboarding) {
      _loadExistingProfile();
    }
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _isLoadingProfile = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc =
          await FirebaseFirestore.instance.collection('mechanics').doc(uid).get();
      if (!doc.exists || !mounted) return;

      final data = doc.data()!;

      shopNameController.text = data['shopName'] as String? ?? '';
      phoneController.text = data['phone'] as String? ?? '';
      emailController.text = data['email'] as String? ?? widget.initialEmail;
      addressController.text = (data['location'] as String?) ??
          (data['address'] as String? ?? '');

      final geoPoint = data['geoPoint'];
      if (geoPoint is GeoPoint) {
        _selectedLatitude = geoPoint.latitude;
        _selectedLongitude = geoPoint.longitude;
      } else {
        _selectedLatitude = (data['latitude'] as num?)?.toDouble();
        _selectedLongitude = (data['longitude'] as num?)?.toDouble();
      }

      final dayStart = data['openingDayStart'] as String?;
      final dayEnd = data['openingDayEnd'] as String?;
      if (dayStart != null || dayEnd != null) {
        openingDayStartController.text = dayStart ?? '';
        openingDayEndController.text = dayEnd ?? '';
      } else {
        final days = _splitRange(data['openingDays'] as String? ?? '');
        openingDayStartController.text = days.$1;
        openingDayEndController.text = days.$2;
      }

      final hourStart = data['openingHourStart'] as String?;
      final hourEnd = data['openingHourEnd'] as String?;
      if (hourStart != null || hourEnd != null) {
        openingHourStartController.text = hourStart ?? '';
        openingHourEndController.text = hourEnd ?? '';
      } else {
        final hours = _splitRange(data['openingHours'] as String? ?? '');
        openingHourStartController.text = hours.$1;
        openingHourEndController.text = hours.$2;
      }

      final specialties = (data['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      if (specialties.isNotEmpty) {
        selectedSpecialties
          ..clear()
          ..addAll(specialties);
        specialtyServices.clear();
        for (final controller in _serviceInputControllers.values) {
          controller.dispose();
        }
        _serviceInputControllers.clear();
        for (final specialty in selectedSpecialties) {
          specialtyServices[specialty] = [];
          _serviceInputControllers[specialty] = TextEditingController();
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    shopNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    openingDayStartController.dispose();
    openingDayEndController.dispose();
    openingHourStartController.dispose();
    openingHourEndController.dispose();
    for (final controller in _serviceInputControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleSpecialty(String specialty) {
    setState(() {
      specialtyValidationError = null;

      if (selectedSpecialties.contains(specialty)) {
        selectedSpecialties.remove(specialty);
        specialtyServices.remove(specialty);
        _serviceInputErrors.remove(specialty);
        _serviceInputControllers.remove(specialty)?.dispose();
      } else {
        selectedSpecialties.add(specialty);
        specialtyServices.putIfAbsent(specialty, () => []);
        _serviceInputControllers[specialty] = TextEditingController();
      }
    });
  }

  void _addService(String specialty, String rawService) {
    final service = rawService.trim();
    if (service.isEmpty) {
      return;
    }

    if (MechanicSpecialtyConfig.isSuggestedForOtherSpecialty(service, specialty)) {
      final owner = MechanicSpecialtyConfig.ownerSpecialtyForService(service);
      setState(() {
        _serviceInputErrors[specialty] =
            'This service belongs to $owner. Add it under that specialty instead.';
      });
      return;
    }

    for (final otherSpecialty in selectedSpecialties) {
      if (otherSpecialty == specialty) {
        continue;
      }

      final otherServices = specialtyServices[otherSpecialty] ?? const [];
      if (otherServices.any(
        (existing) => existing.toLowerCase() == service.toLowerCase(),
      )) {
        setState(() {
          _serviceInputErrors[specialty] =
              'This service is already listed under $otherSpecialty.';
        });
        return;
      }
    }

    setState(() {
      specialtyValidationError = null;
      _serviceInputErrors[specialty] = null;
      final services = specialtyServices.putIfAbsent(specialty, () => []);
      final alreadyAdded = services.any(
        (existing) => existing.toLowerCase() == service.toLowerCase(),
      );
      if (!alreadyAdded) {
        services.add(service);
      }
      _serviceInputControllers[specialty]?.clear();
    });
  }

  void _removeService(String specialty, String service) {
    setState(() {
      specialtyServices[specialty]?.remove(service);
    });
  }

  bool _validateSpecialtiesAndServices() {
    if (selectedSpecialties.isEmpty) {
      setState(() {
        specialtyValidationError = 'Select at least one specialty';
      });
      return false;
    }

    for (final specialty in selectedSpecialties) {
      final services = specialtyServices[specialty] ?? const [];
      if (services.isEmpty) {
        setState(() {
          specialtyValidationError =
              'Add at least one service for $specialty';
        });
        return false;
      }
    }

    setState(() {
      specialtyValidationError = null;
    });
    return true;
  }

  Widget _buildSpecialtySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Specialties'),
        const Text(
          'Select one or more specialties you offer',
          style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _specialtyOptions.map((specialty) {
            final isSelected = selectedSpecialties.contains(specialty);

            return FilterChip(
              label: Text(specialty),
              selected: isSelected,
              onSelected: (_) => _toggleSpecialty(specialty),
              selectedColor: const Color(0xFFEAF0FF),
              checkmarkColor: const Color(0xFF1F3FAF),
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFF1F3FAF)
                    : const Color(0xFF344054),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF1F3FAF)
                    : const Color(0xFFD0D5DD),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }).toList(),
        ),
        if (specialtyValidationError != null) ...[
          const SizedBox(height: 8),
          Text(
            specialtyValidationError!,
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildServicesSection(String specialty) {
    final services = specialtyServices[specialty] ?? const [];
    final suggestions =
        MechanicSpecialtyConfig.suggestedServices[specialty] ?? const [];
    final inputController = _serviceInputControllers[specialty];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7DDE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            specialty,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add only services related to this specialty',
            style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 12),
          if (suggestions.isNotEmpty) ...[
            const Text(
              'Suggested services',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.map((service) {
                final isAdded = services.contains(service);

                return ActionChip(
                  label: Text(service),
                  onPressed: isAdded
                      ? null
                      : () => _addService(specialty, service),
                  backgroundColor: isAdded
                      ? const Color(0xFFE4E7EC)
                      : const Color(0xFFEAF0FF),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: isAdded
                        ? const Color(0xFF98A2B3)
                        : const Color(0xFF1F3FAF),
                  ),
                  side: BorderSide(
                    color: isAdded
                        ? const Color(0xFFD0D5DD)
                        : const Color(0xFFBFD0FF),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: inputController,
                  decoration: _inputDecoration('Add custom $specialty service')
                      .copyWith(
                    errorText: _serviceInputErrors[specialty],
                  ),
                  onChanged: (_) {
                    if (_serviceInputErrors[specialty] != null) {
                      setState(() {
                        _serviceInputErrors[specialty] = null;
                      });
                    }
                  },
                  onSubmitted: (value) => _addService(specialty, value),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    _addService(
                      specialty,
                      inputController?.text ?? '',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F3FAF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          if (services.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: services.map((service) {
                return Chip(
                  label: Text(service),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeService(specialty, service),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFD0D5DD)),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF344054),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSplitRangeFields({
    required String label,
    required TextEditingController startController,
    required TextEditingController endController,
    required String startHint,
    required String endHint,
    required String emptyError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: startController,
                enabled: !_isLoadingProfile,
                decoration: _inputDecoration(startHint),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return emptyError;
                  }
                  return null;
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'to',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: endController,
                enabled: !_isLoadingProfile,
                decoration: _inputDecoration(endHint),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return emptyError;
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1F3FAF)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) {
      return;
    }

    final bytes = await pickedFile.readAsBytes();

    if (!mounted) {
      return;
    }

    setState(() {
      selectedPhotoBytes = bytes;
      photoScale = 1.0;
      photoAlignmentX = 0.0;
      photoAlignmentY = 0.0;
    });
  }

  Widget _buildPhotoBox() {
    final hasPhoto = selectedPhotoBytes != null && selectedPhotoBytes!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD7DDE8)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: hasPhoto
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final boxWidth = constraints.maxWidth;
                          final boxHeight = constraints.maxHeight;

                          return GestureDetector(
                            onScaleStart: (_) {
                              _gestureStartScale = photoScale;
                            },
                            onScaleUpdate: (details) {
                              setState(() {
                                photoScale = (_gestureStartScale * details.scale)
                                    .clamp(1.0, 2.0);
                                photoAlignmentX = (photoAlignmentX +
                                        details.focalPointDelta.dx /
                                            (boxWidth / 2))
                                    .clamp(-1.0, 1.0);
                                photoAlignmentY = (photoAlignmentY +
                                        details.focalPointDelta.dy /
                                            (boxHeight / 2))
                                    .clamp(-1.0, 1.0);
                              });
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Align(
                                  alignment: Alignment(
                                    photoAlignmentX,
                                    photoAlignmentY,
                                  ),
                                  child: Transform.scale(
                                    scale: photoScale,
                                    child: Image.memory(
                                      selectedPhotoBytes!,
                                      fit: BoxFit.cover,
                                      width: boxWidth,
                                      height: boxHeight,
                                    ),
                                  ),
                                ),
                                IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.35),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_camera_outlined,
                              size: 34,
                              color: Color(0xFF667085),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Upload your photo",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF344054),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Tap to choose a picture",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF667085),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: ElevatedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: Text(hasPhoto ? "Change Photo" : "Upload Photo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F3FAF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasPhoto) ...[
          const SizedBox(height: 8),
          const Text(
            'Pinch to zoom · Drag to move',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
        ],
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF101828),
          ),
        ),
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    LatLng? initialPosition;
    if (_selectedLatitude != null && _selectedLongitude != null) {
      initialPosition = LatLng(_selectedLatitude!, _selectedLongitude!);
    }

    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          initialPosition: initialPosition,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _selectedLatitude = result.latitude;
      _selectedLongitude = result.longitude;
      addressController.text = result.address;
    });
  }

  Future<void> _saveProfile() async {
    if (!_validateSpecialtiesAndServices()) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final specialization = selectedSpecialties.join(', ');

      await FirebaseFirestore.instance.collection('mechanics').doc(uid).set(
        {
          'shopName': shopNameController.text.trim(),
          'location': addressController.text.trim(),
          'address': addressController.text.trim(),
          'phone': phoneController.text.trim(),
          'specialization': specialization,
          'specialties': selectedSpecialties,
          'openingDays': _combinedOpeningDays,
          'openingHours': _combinedOpeningHours,
          'openingDayStart': openingDayStartController.text.trim(),
          'openingDayEnd': openingDayEndController.text.trim(),
          'openingHourStart': openingHourStartController.text.trim(),
          'openingHourEnd': openingHourEndController.text.trim(),
          'isDemo': false,
          if (widget.isOnboarding) 'isVerified': false,
          if (_selectedLatitude != null && _selectedLongitude != null) ...{
            'latitude': _selectedLatitude,
            'longitude': _selectedLongitude,
            'geoPoint': GeoPoint(_selectedLatitude!, _selectedLongitude!),
          },
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      final profileData = MechanicProfileData(
        email: emailController.text.trim(),
        shopName: shopNameController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        specialties: List<String>.from(selectedSpecialties),
        specialtyServices: {
          for (final specialty in selectedSpecialties)
            specialty:
                List<String>.from(specialtyServices[specialty] ?? const []),
        },
        openingDays: _combinedOpeningDays,
        openingHours: _combinedOpeningHours,
        photoBytes: selectedPhotoBytes,
        photoScale: photoScale,
        photoAlignmentX: photoAlignmentX,
        photoAlignmentY: photoAlignmentY,
      );

      if (widget.isOnboarding) {
        _goToDashboard(profileData);
      } else {
        Navigator.pop(context, profileData);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _goToDashboard(MechanicProfileData profileData) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MechanicDashboardScreen(profileData: profileData),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 54,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              color: const Color(0xFF1F3FAF),
              child: Row(
                children: [
                  if (widget.isOnboarding)
                    const SizedBox(width: 40)
                  else
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back_ios,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Back",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Text(
                    widget.isOnboarding ? "Complete Shop Profile" : "Edit Shop Profile",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: _isLoadingProfile
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1F3FAF)),
                    )
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD7DDE8)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            _buildPhotoBox(),
                            const SizedBox(height: 18),

                            _label("Shop Name"),
                            TextFormField(
                              controller: shopNameController,
                              enabled: !_isLoadingProfile,
                              decoration: _inputDecoration("Enter shop name"),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Shop name is required";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _label("Phone Number"),
                            TextFormField(
                              controller: phoneController,
                              enabled: !_isLoadingProfile,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration("Enter phone number"),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Phone number is required";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _label("Email Address"),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: true,
                              decoration: _inputDecoration("Enter email address"),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Email is required";
                                }
                                if (!RegExp(
                                  r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                                ).hasMatch(value.trim())) {
                                  return "Enter a valid email";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 6),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "This email is fixed from sign-up and cannot be changed.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF667085),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            _label("Address"),
                            TextFormField(
                              controller: addressController,
                              readOnly: true,
                              maxLines: 2,
                              decoration: _inputDecoration(
                                "Select your shop location on the map",
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Address is required";
                                }
                                if (_selectedLatitude == null ||
                                    _selectedLongitude == null) {
                                  return "Please select your location on the map";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _isLoadingProfile ? null : _openLocationPicker,
                                icon: const Icon(Icons.map_outlined, size: 18),
                                label: const Text('Select on Map'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1F3FAF),
                                  side: const BorderSide(color: Color(0xFF1F3FAF)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            _buildSpecialtySelector(),
                            if (selectedSpecialties.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _label('Services by Specialty'),
                              ...selectedSpecialties.map(_buildServicesSection),
                            ],
                            const SizedBox(height: 14),

                            _buildSplitRangeFields(
                              label: 'Opening Days',
                              startController: openingDayStartController,
                              endController: openingDayEndController,
                              startHint: 'Mon',
                              endHint: 'Fri',
                              emptyError: 'Required',
                            ),
                            const SizedBox(height: 14),
                            _buildSplitRangeFields(
                              label: 'Opening Hours',
                              startController: openingHourStartController,
                              endController: openingHourEndController,
                              startHint: '8 AM',
                              endHint: '6 PM',
                              emptyError: 'Required',
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: (_isSaving || _isLoadingProfile)
                                    ? null
                                    : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F3FAF),
                                  disabledBackgroundColor: const Color(0xFFBFD0FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        widget.isOnboarding
                                            ? "Save & Continue"
                                            : "Save Changes",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}