class MechanicSpecialtyConfig {
  static const String mechanical = 'Machinal (engine & transmission)';
  static const String electrical = 'Electrical';
  static const String tyres = 'Car tyres';

  static const List<String> options = [
    mechanical,
    electrical,
    tyres,
  ];

  static const Map<String, List<String>> suggestedServices = {
    mechanical: [
      'Oil Change',
      'Engine Diagnostics',
      'Transmission Repair',
      'Brake Service',
      'AC Service',
      'Coolant Flush',
    ],
    electrical: [
      'Battery Replacement',
      'Alternator Repair',
      'Starter Motor Repair',
      'Wiring & Fuse Repair',
      'Sensor Diagnostics',
      'Lighting Repair',
    ],
    tyres: [
      'Tire Rotation',
      'Wheel Alignment',
      'Puncture Repair',
      'Tire Replacement',
      'Wheel Balancing',
      'Rim Repair',
    ],
  };

  static String? ownerSpecialtyForService(String service) {
    final normalized = service.trim().toLowerCase();

    for (final entry in suggestedServices.entries) {
      for (final suggested in entry.value) {
        if (suggested.toLowerCase() == normalized) {
          return entry.key;
        }
      }
    }

    return null;
  }

  static bool isSuggestedForOtherSpecialty(
    String service,
    String currentSpecialty,
  ) {
    final owner = ownerSpecialtyForService(service);
    return owner != null && owner != currentSpecialty;
  }
}
