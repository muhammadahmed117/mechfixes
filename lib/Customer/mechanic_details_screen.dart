import 'package:flutter/material.dart';
import 'package:mechfixes/Customer/mechanic_map_screen.dart';
import 'package:mechfixes/Customer/ratings_reviews_screen.dart';
import 'package:mechfixes/Customer/widgets/mechanic_rating_display.dart';
import 'package:mechfixes/core/session/app_session.dart';
import 'package:url_launcher/url_launcher.dart';

class MechanicDetailsScreen extends StatelessWidget {
  const MechanicDetailsScreen({
    super.key,
    required this.imageUrl,
    this.mechanicId = AppSession.demoMechanicId,
    this.mechanicName = 'Elite Auto Service',
    this.specialty = 'All Services',
    this.rating = '4.9',
    this.reviews = '245 reviews',
    this.address = '123 Main St, San Francisco',
    this.distance = '0.8 miles away',
    this.phone = '+1 234 567 8900',
    this.latitude,
    this.longitude,
    this.openingDays = '',
    this.openingHours = '',
    this.services = const [],
  });

  factory MechanicDetailsScreen.fromMechanic(Map<String, dynamic> mechanic) {
    final services = mechanic['services'];
    return MechanicDetailsScreen(
      imageUrl: mechanic['image'] as String? ?? '',
      mechanicId: mechanic['id'] as String? ?? AppSession.demoMechanicId,
      mechanicName: mechanic['name'] as String? ?? 'Mechanic',
      specialty: mechanic['specialty'] as String? ?? 'General Service',
      rating: mechanic['rating'] as String? ?? '4.8',
      reviews: mechanic['reviews'] as String? ?? '0 reviews',
      address: mechanic['address'] as String? ?? '',
      distance: '${mechanic['distance'] ?? ''} away',
      phone: mechanic['phone'] as String? ?? '+1 000 000 0000',
      latitude: (mechanic['latitude'] as num?)?.toDouble(),
      longitude: (mechanic['longitude'] as num?)?.toDouble(),
      openingDays: mechanic['openingDays'] as String? ?? '',
      openingHours: mechanic['openingHours'] as String? ?? '',
      services: services is List
          ? services.map((item) => item.toString()).toList()
          : const [],
    );
  }

  final String imageUrl;
  final String mechanicId;
  final String mechanicName;
  final String specialty;
  final String rating;
  final String reviews;
  final String address;
  final String distance;
  final String phone;
  final double? latitude;
  final double? longitude;
  final String openingDays;
  final String openingHours;
  final List<String> services;

  String get _hoursText {
    final days = openingDays.trim();
    final hours = openingHours.trim();
    if (days.isNotEmpty && hours.isNotEmpty) return '$days: $hours';
    if (hours.isNotEmpty) return hours;
    if (days.isNotEmpty) return days;
    return 'Hours not set';
  }

  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Future<void> _openMapDirections(BuildContext context) {
    return MechanicMapScreen.open(
      context,
      mechanicName: mechanicName,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFF1F3FAF),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text("Back", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "Mechanic Details",
                    style: TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD0D5DD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                            child: imageUrl.trim().isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _imagePlaceholder(),
                                  )
                                : _imagePlaceholder(),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mechanicName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            specialty,
                                            style: const TextStyle(
                                              color: Color(0xFF1F3FAF),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                RatingsReviewsScreen(
                                              mechanicId: mechanicId,
                                              mechanicName: mechanicName,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.star_outline,
                                        size: 16,
                                      ),
                                      label: const Text("View Ratings"),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Color(0xFFD0D5DD),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                MechanicRatingDisplay(
                                  mechanicId: mechanicId,
                                  starSize: 16,
                                  ratingStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF101828),
                                  ),
                                  reviewStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF667085),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoBox(
                                        Icons.location_on_outlined,
                                        "Location",
                                        "$address\n$distance",
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _infoBox(
                                        Icons.phone_outlined,
                                        "Contact",
                                        phone,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoBox(
                                        Icons.access_time,
                                        "Hours",
                                        _hoursText,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _infoBox(
                                        Icons.attach_money,
                                        "Average Cost",
                                        "\$\$\$ - Premium",
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD0D5DD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Services Offered",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: services.isEmpty
                                ? [
                                    _ServiceChip(specialty),
                                  ]
                                : services
                                    .map((service) => _ServiceChip(service))
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F3FAF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Ready to visit?",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Visit the shop or request the mechanic to come to your location.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _openMapDirections(context),
                                    icon: const Icon(Icons.navigation_outlined),
                                    label: const Text('Directions'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor:
                                          const Color(0xFF1F3FAF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _makePhoneCall(phone, context),
                                    icon: const Icon(Icons.phone),
                                    label: const Text('Call'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor:
                                          const Color(0xFF1F3FAF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  static Widget _imagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: const Color(0xFFF2F4F7),
      child: const Icon(
        Icons.image_outlined,
        size: 48,
        color: Color(0xFF98A2B3),
      ),
    );
  }

  static Widget _infoBox(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF667085)),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String text;
  const _ServiceChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
