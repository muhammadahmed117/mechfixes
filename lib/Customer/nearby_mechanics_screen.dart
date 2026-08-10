import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mechfixes/Customer/issue_category.dart';
import 'package:mechfixes/Customer/mechanic_details_screen.dart';
import 'package:mechfixes/Customer/mechanic_map_screen.dart';
import 'package:mechfixes/Customer/mechanics_data.dart';
import 'package:mechfixes/Customer/widgets/mechanic_rating_display.dart';
import 'package:mechfixes/core/localization/app_text.dart';
import 'package:mechfixes/core/localization/language_toggle_button.dart';
import 'package:mechfixes/services/location_service.dart';
import 'package:mechfixes/services/mechanics_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyMechanicsScreen extends StatefulWidget {
  const NearbyMechanicsScreen({
    super.key,
    this.issueCategory,
    this.issueDescription,
  });

  final IssueCategory? issueCategory;
  final String? issueDescription;

  @override
  State<NearbyMechanicsScreen> createState() => _NearbyMechanicsScreenState();
}

class _NearbyMechanicsScreenState extends State<NearbyMechanicsScreen> {
  String selectedSort = "Distance";
  final MechanicsRepository _mechanicsRepository = MechanicsRepository.instance;
  final LocationService _locationService = LocationService.instance;

  String _locationLabel = '';
  bool _loadingLocation = true;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _resolveUserLocation();
  }

  Future<void> _resolveUserLocation() async {
    setState(() => _loadingLocation = true);

    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;

      if (position == null) {
        setState(() {
          _userPosition = null;
          _locationLabel = AppText.of(
            context,
            english: 'Location unavailable — enable GPS',
            romanUrdu: 'Location nahi mili — GPS on karein',
          );
          _loadingLocation = false;
        });
        return;
      }

      final address = await _locationService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;

      final coords =
          '${position.latitude.toStringAsFixed(5)}, '
          '${position.longitude.toStringAsFixed(5)}';

      setState(() {
        _userPosition = position;
        _locationLabel =
            (address != null && address.trim().isNotEmpty) ? address : coords;
        _loadingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userPosition = null;
        _locationLabel = AppText.of(
          context,
          english: 'Could not fetch location',
          romanUrdu: 'Location hasil nahi hui',
        );
        _loadingLocation = false;
      });
    }
  }

  List<Map<String, dynamic>> _sortMechanics(
    List<Map<String, dynamic>> mechanics,
  ) {
    final sorted = List<Map<String, dynamic>>.from(mechanics);

    if (selectedSort == "Rating") {
      sorted.sort(
        (a, b) => _readRatingString(
          b["rating"],
        ).compareTo(_readRatingString(a["rating"])),
      );
    } else {
      sorted.sort(
        (a, b) => _readDistanceValue(a).compareTo(_readDistanceValue(b)),
      );
    }

    return sorted;
  }

  double _readDistanceValue(Map<String, dynamic> mechanic) {
    final value = mechanic['distanceValue'];
    if (value is num) return value.toDouble();
    return 999;
  }

  double _readRatingString(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  List<Map<String, dynamic>> _fallbackMechanics() {
    return _sortMechanics(MechanicsData.forCategory(widget.issueCategory));
  }

  void _openMechanicProfile(Map<String, dynamic> mechanic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MechanicDetailsScreen.fromMechanic(mechanic),
      ),
    );
  }

  Future<void> _openMapDirections(Map<String, dynamic> mechanic) {
    return MechanicMapScreen.open(
      context,
      mechanicName: mechanic['name'] as String? ?? 'Mechanic',
      address: mechanic['address'] as String? ?? '',
      latitude: (mechanic['latitude'] as num?)?.toDouble(),
      longitude: (mechanic['longitude'] as num?)?.toDouble(),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleaned = phoneNumber.trim();
    if (cleaned.isEmpty || cleaned == '+1 000 000 0000') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppText.of(
              context,
              english: 'Phone number not available',
              romanUrdu: 'Phone number mojood nahin',
            ),
          ),
        ),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppText.of(
              context,
              english: 'Could not launch phone dialer',
              romanUrdu: 'Phone dialer nahin khul saka',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.issueCategory;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 60,
              color: const Color(0xFF1F3FAF),
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
                          size: 15,
                        ),
                        SizedBox(width: 4),
                        Text(
                          AppText.of(
                            context,
                            english: 'Back',
                            romanUrdu: 'Wapas',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        AppText.of(
                          context,
                          english: 'Nearby Mechanics',
                          romanUrdu: 'Qareebi Mechanics',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const LanguageToggleButton(compact: true),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (category != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFD0FF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.filter_list_rounded,
                                  size: 18,
                                  color: Color(0xFF1F3FAF),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppText.of(
                                      context,
                                      english:
                                          'Showing ${category.label} mechanics',
                                      romanUrdu:
                                          '${category.label} ke mechanics dikhaye ja rahe hain',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F3FAF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.issueDescription != null &&
                                widget.issueDescription!.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                AppText.of(
                                  context,
                                  english:
                                      'Issue: ${widget.issueDescription!.trim()}',
                                  romanUrdu:
                                      'Masla: ${widget.issueDescription!.trim()}',
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475467),
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              AppText.of(
                                context,
                                english:
                                    'Multi-specialty shops appear when they cover this category.',
                                romanUrdu:
                                    'Is category ki service dene wali dukanein dikhayi jati hain.',
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF667085),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F3FAF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppText.of(
                                    context,
                                    english: 'Your Location',
                                    romanUrdu: 'Aap ki Jagah',
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (_loadingLocation)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.8,
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppText.of(
                                          context,
                                          english: 'Detecting location…',
                                          romanUrdu: 'Location dhoondh rahe hain…',
                                        ),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  Text(
                                    _locationLabel.isEmpty
                                        ? AppText.of(
                                            context,
                                            english: 'Location not set',
                                            romanUrdu: 'Location set nahi',
                                          )
                                        : _locationLabel,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                    ),
                                  ),
                                  if (_userPosition != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_userPosition!.latitude.toStringAsFixed(5)}, '
                                      '${_userPosition!.longitude.toStringAsFixed(5)}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD7DDE8)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.filter_alt_outlined,
                            size: 16,
                            color: Color(0xFF667085),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppText.of(
                              context,
                              english: 'Sort by:',
                              romanUrdu: 'Tarteeb:',
                            ),
                            style: const TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          _sortChip("Distance"),
                          const SizedBox(width: 8),
                          _sortChip("Rating"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _mechanicsRepository.watchDisplayMechanics(
                        category: category,
                      ),
                      builder: (context, snapshot) {
                        if (!MechanicsRepository.isFirebaseReady) {
                          debugPrint(
                            '[NearbyMechanics] Firebase not ready, using fallback data',
                          );
                          final mechanics = _sortMechanics(
                            _fallbackMechanics(),
                          );
                          if (mechanics.isEmpty) {
                            return _emptyState(category);
                          }
                          return _mechanicsGrid(mechanics, category);
                        }

                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1F3FAF),
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          debugPrint(
                            '[NearbyMechanics] Stream error: ${snapshot.error}',
                          );
                          return _emptyState(
                            category,
                            message:
                                'Could not load mechanics. Please try again.',
                          );
                        }

                        final mechanics = _sortMechanics(
                          snapshot.data ?? const [],
                        );
                        debugPrint(
                          '[NearbyMechanics] Rendering ${mechanics.length} mechanics',
                        );

                        if (mechanics.isEmpty) {
                          return _emptyState(category);
                        }

                        return _mechanicsGrid(mechanics, category);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IssueCategory? category, {String? message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7DDE8)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 42,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message ??
                AppText.of(
                  context,
                  english: 'No ${category?.label ?? ''} mechanics found nearby',
                  romanUrdu:
                      'Qareeb koi ${category?.label ?? ''} mechanic nahin mila',
                ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppText.of(
              context,
              english: 'Try browsing all nearby mechanics or check back later.',
              romanUrdu:
                  'Tamam qareebi mechanics dekhein ya baad mein dobara check karein.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
          ),
        ],
      ),
    );
  }

  Widget _mechanicsGrid(
    List<Map<String, dynamic>> mechanics,
    IssueCategory? category,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const crossAxisCount = 2;
        final width = constraints.maxWidth;
        final cardWidth =
            (width - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final cardHeight = (cardWidth * 1.75).clamp(300.0, 360.0);

        return GridView.builder(
          itemCount: mechanics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) {
            final mechanic = mechanics[index];
            return _mechanicCard(mechanic, category);
          },
        );
      },
    );
  }

  Widget _sortChip(String title) {
    final bool isSelected = selectedSort == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSort = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F3FAF) : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF667085),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _mechanicCard(
    Map<String, dynamic> mechanic,
    IssueCategory? activeCategory,
  ) {
    final specialties = List<IssueCategory>.from(
      mechanic["specialties"] as List,
    );

    final visibleSpecialties = specialties.take(2).toList();
    final hiddenSpecialtyCount = specialties.length - visibleSpecialties.length;

    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD7DDE8)),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openMechanicProfile(mechanic),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 88,
                        child: mechanic["image"] != null
                            ? Image.network(
                                mechanic["image"],
                                width: double.infinity,
                                height: 88,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: const Color(0xFFF2F4F7),
                                child: const Icon(
                                  Icons.image_outlined,
                                  size: 36,
                                  color: Color(0xFF98A2B3),
                                ),
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mechanic["name"],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF101828),
                                ),
                              ),
                              const SizedBox(height: 4),
                              MechanicRatingDisplay(
                                mechanicId: mechanic['id'] as String? ?? '',
                                starSize: 14,
                                ratingStyle: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF101828),
                                ),
                                reviewStyle: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF667085),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${mechanic["distance"]} • ${mechanic["address"]}",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  height: 1.3,
                                  color: Color(0xFF667085),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  ...visibleSpecialties.map((specialty) {
                                    final isMatch =
                                        activeCategory != null &&
                                        specialty == activeCategory;

                                    return _specialtyChip(
                                      label: specialty.label,
                                      isMatch: isMatch,
                                    );
                                  }),
                                  if (hiddenSpecialtyCount > 0)
                                    _specialtyChip(
                                      label: '+$hiddenSpecialtyCount',
                                      isMatch: false,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: const Color(0xFF1F3FAF),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => _openMapDirections(mechanic),
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.navigation_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                AppText.of(
                                  context,
                                  english: 'Directions',
                                  romanUrdu: 'Rasta',
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFD7DDE8)),
                    ),
                    child: InkWell(
                      onTap: () =>
                          _makePhoneCall(mechanic['phone'] as String? ?? ''),
                      borderRadius: BorderRadius.circular(8),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.call_outlined,
                          size: 18,
                          color: Color(0xFF667085),
                        ),
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

  Widget _specialtyChip({required String label, required bool isMatch}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isMatch ? const Color(0xFFEAF0FF) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isMatch ? const Color(0xFF1F3FAF) : const Color(0xFFD7DDE8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: isMatch ? FontWeight.w600 : FontWeight.w500,
          color: isMatch ? const Color(0xFF1F3FAF) : const Color(0xFF667085),
        ),
      ),
    );
  }
}
