import 'dart:typed_data';

class MechanicProfileData {
  const MechanicProfileData({
    this.email = '',
    this.shopName = '',
    this.phone = '',
    this.address = '',
    this.specialties = const [],
    this.specialtyServices = const {},
    this.selectedSkills = const [],
    this.openingDays = '',
    this.openingHours = '',
    this.photoBytes,
    this.photoScale = 1.0,
    this.photoAlignmentX = 0.0,
    this.photoAlignmentY = 0.0,
  });

  final String email;
  final String shopName;
  final String phone;
  final String address;
  final List<String> specialties;
  final Map<String, List<String>> specialtyServices;
  final List<String> selectedSkills;
  final String openingDays;
  final String openingHours;
  final Uint8List? photoBytes;
  final double photoScale;
  final double photoAlignmentX;
  final double photoAlignmentY;

  String get specialty => specialties.join(' · ');

  List<String> get allServices {
    final services = <String>[];
    for (final specialty in specialties) {
      services.addAll(specialtyServices[specialty] ?? const []);
    }
    return services;
  }
}
