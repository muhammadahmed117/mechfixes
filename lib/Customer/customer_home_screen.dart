import 'package:flutter/material.dart';
import 'package:mechfixes/Customer/ai_diagnostic_screen.dart';
import 'package:mechfixes/Customer/customer_profile_screen.dart';
import 'package:mechfixes/Customer/electrical_issues_screen.dart';
import 'package:mechfixes/Customer/mechanical_issues_screen.dart';
import 'package:mechfixes/Customer/mechanic_details_screen.dart';
import 'package:mechfixes/Customer/nearby_mechanics_screen.dart';
import 'package:mechfixes/Customer/tyres_wheel_issues_screen.dart';
import 'package:mechfixes/Customer/widgets/mechanic_rating_display.dart';
import 'package:mechfixes/core/navigation/auth_navigation.dart';
import 'package:mechfixes/data/models/mechanic_record.dart';
import 'package:mechfixes/services/mechanics_repository.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key, this.selectedCategory = ''});

  final String selectedCategory;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  static const _primary = Color(0xFF1F3FAF);

  int _selectedCategory = -1;
  String _searchQuery = '';

  final _searchCtrl = TextEditingController();
  final MechanicsRepository _mechanicsRepository = MechanicsRepository.instance;

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Mechanical',
      'subtitle': 'Engine, transmission, and mechanical issues',
      'icon': Icons.settings_outlined,
    },
    {
      'title': 'Tyres & Wheels',
      'subtitle': 'Tire wear, alignment, and wheel problems',
      'icon': Icons.directions_car_outlined,
    },
    {
      'title': 'Electrical',
      'subtitle': 'Battery, lights, and electrical systems',
      'icon': Icons.flash_on_outlined,
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Mechanic list processing ─────────────────────────────────────────────

  List<MechanicRecord> _processMechanics(List<MechanicRecord> records) {
    debugPrint('[CustomerHome] Received ${records.length} mechanics from repository');

    var list = List<MechanicRecord>.from(records);

    if (widget.selectedCategory.isNotEmpty) {
      final category = widget.selectedCategory.toLowerCase();
      final beforeCategory = list.length;
      list = list.where((record) {
        final specialization = record.specialties.join(' ').toLowerCase();
        final shopName = record.shopName.toLowerCase();
        final fullName = record.fullName.toLowerCase();
        return specialization.contains(category) ||
            shopName.contains(category) ||
            fullName.contains(category) ||
            record.specialties.any(
              (specialty) =>
                  specialty.toLowerCase().contains(category) ||
                  category.contains(specialty.toLowerCase()),
            );
      }).toList();
      debugPrint(
        '[CustomerHome] Category filter removed '
        '${beforeCategory - list.length} mechanics',
      );
    }

    list.sort((a, b) => b.rating.compareTo(a.rating));

    if (list.length > 5) {
      list = list.sublist(0, 5);
    }

    debugPrint('[CustomerHome] Showing ${list.length} mechanics after processing');
    return list;
  }

  List<MechanicRecord> _filter(List<MechanicRecord> records) {
    if (_searchQuery.isEmpty) return records;
    final q = _searchQuery.toLowerCase();
    final filtered = records.where((record) {
      final shopName = record.shopName.toLowerCase();
      final fullName = record.fullName.toLowerCase();
      final specialization = record.specialties.join(' ').toLowerCase();
      final location = record.address.toLowerCase();
      return shopName.contains(q) ||
          fullName.contains(q) ||
          specialization.contains(q) ||
          location.contains(q);
    }).toList();

    if (filtered.length != records.length) {
      debugPrint(
        '[CustomerHome] Search filter removed ${records.length - filtered.length} mechanics',
      );
    }

    return filtered;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiDiagnosticScreen()),
        ),
        backgroundColor: _primary,
        elevation: 4,
        icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
        label: const Text(
          'AI Mechanic',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              color: _primary,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.directions_car_outlined,
                      size: 18,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Mechfixes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'AI Mechanic',
                    icon: const Icon(Icons.smart_toy_outlined,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiDiagnosticScreen(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Profile',
                    icon: const Icon(Icons.person_outline, color: Colors.white, size: 20),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerProfileScreen(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Logout',
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                    onPressed: () => logoutToLogin(context),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Page title ──
                    const Text(
                      "What's the issue?",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select a category or search for a mechanic below.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF475467)),
                    ),
                    const SizedBox(height: 24),

                    // ── AI Diagnostic promo card ──
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiDiagnosticScreen(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1F3FAF), Color(0xFF3B5BDB)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.psychology_outlined,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI Car Diagnostic',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Describe symptoms — get instant fault prediction & DIY advice',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Category cards ──
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 800) {
                          return Row(
                            children: List.generate(
                              _categories.length,
                              (i) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: i == _categories.length - 1 ? 0 : 16,
                                  ),
                                  child: _CategoryCard(
                                    item: _categories[i],
                                    isSelected: _selectedCategory == i,
                                    onTap: () => _onCategoryTap(i),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: List.generate(
                            _categories.length,
                            (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _CategoryCard(
                                item: _categories[i],
                                isSelected: _selectedCategory == i,
                                onTap: () => _onCategoryTap(i),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Browse all mechanics button ──
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NearbyMechanicsScreen(),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _primary, width: 1.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.map_outlined,
                            color: _primary, size: 18),
                        label: const Text(
                          'Find Mechanics Nearby',
                          style: TextStyle(
                            color: _primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ── Section header ──
                    const Text(
                      'Find a Mechanic',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Search bar ──
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search by name or specialization…',
                        hintStyle: const TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search,
                            color: Color(0xFF98A2B3), size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    size: 18, color: Color(0xFF98A2B3)),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFD0D5DD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Mechanics stream ──
                    StreamBuilder<List<MechanicRecord>>(
                      stream: _mechanicsRepository.watchVerifiedMechanics(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(color: _primary),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          debugPrint(
                            '[CustomerHome] Stream error: ${snapshot.error}',
                          );
                          return _InfoTile(
                            icon: Icons.error_outline,
                            message: 'Could not load mechanics.',
                            color: Colors.redAccent,
                          );
                        }

                        final processed =
                            _processMechanics(snapshot.data ?? const []);
                        final filtered = _filter(processed);

                        if (filtered.isEmpty) {
                          return const _InfoTile(
                            icon: Icons.engineering_outlined,
                            message: 'No mechanics found nearby.',
                            color: Color(0xFF98A2B3),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _MechanicCard(record: filtered[index]);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCategoryTap(int index) {
    setState(() => _selectedCategory = index);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          switch (index) {
            case 0:
              return const MechanicalIssuesScreen();
            case 1:
              return const TyresWheelIssuesScreen();
            case 2:
              return const ElectricalIssuesScreen();
            default:
              return const MechanicalIssuesScreen();
          }
        },
      ),
    );
  }
}

// ─── Category card ─────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1F3FAF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : const Color(0xFFD9DFEA),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? primary : const Color(0xFF2F6FED),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item['icon'] as IconData,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              item['title'] as String,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item['subtitle'] as String,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF475467),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mechanic card ──────────────────────────────────────────────────────────

class _MechanicCard extends StatelessWidget {
  const _MechanicCard({required this.record});

  final MechanicRecord record;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1F3FAF);

    final fullName = record.displayName;
    final specialization = record.specialties.isNotEmpty
        ? record.specialties.join(' · ')
        : 'General Services';
    final location = record.address.trim().isNotEmpty
        ? record.address
        : 'Location not set';
    final phone =
        record.phone.trim().isNotEmpty ? record.phone : 'Phone not set';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    void openProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MechanicDetailsScreen.fromMechanic(
            record.toDisplayMap(),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE4E7EF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE8EDF8),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        specialization,
                        style: const TextStyle(
                          fontSize: 12,
                          color: primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                MechanicRatingDisplay(
                  mechanicId: record.uid,
                  starSize: 16,
                  ratingStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                  reviewStyle: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F2F7)),
            const SizedBox(height: 12),
            _Row(
              icon: Icons.location_on_outlined,
              text: location,
            ),
            const SizedBox(height: 6),
            _Row(
              icon: Icons.phone_outlined,
              text: phone,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: openProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'View Profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF8A94A6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: color.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
