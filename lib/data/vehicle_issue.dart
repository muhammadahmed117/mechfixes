import 'package:mechfixes/Customer/issue_category.dart';

class VehicleIssue {
  const VehicleIssue({
    required this.id,
    required this.title,
    required this.category,
  });

  final String id;
  final String title;
  final IssueCategory category;
}

class VehicleIssueCatalog {
  static const List<VehicleIssue> all = [
    VehicleIssue(
      id: 'mech_engine_wont_start',
      title: "Engine won't start",
      category: IssueCategory.mechanical,
    ),
    VehicleIssue(
      id: 'mech_strange_noise',
      title: 'Strange engine noise',
      category: IssueCategory.mechanical,
    ),
    VehicleIssue(
      id: 'mech_transmission',
      title: 'Transmission slipping',
      category: IssueCategory.mechanical,
    ),
    VehicleIssue(
      id: 'mech_oil_leak',
      title: 'Oil leak detected',
      category: IssueCategory.mechanical,
    ),
    VehicleIssue(
      id: 'mech_overheating',
      title: 'Overheating engine',
      category: IssueCategory.mechanical,
    ),
    VehicleIssue(
      id: 'mech_check_engine',
      title: 'Check engine light on',
      category: IssueCategory.mechanical,
    ),
    VehicleIssue(
      id: 'tyre_flat',
      title: 'Flat tire or puncture',
      category: IssueCategory.tyresAndWheels,
    ),
    VehicleIssue(
      id: 'tyre_vibration',
      title: 'Steering wheel vibration',
      category: IssueCategory.tyresAndWheels,
    ),
    VehicleIssue(
      id: 'tyre_low_pressure',
      title: 'Low tire pressure',
      category: IssueCategory.tyresAndWheels,
    ),
    VehicleIssue(
      id: 'tyre_pulling',
      title: 'Vehicle pulling to one side',
      category: IssueCategory.tyresAndWheels,
    ),
    VehicleIssue(
      id: 'tyre_uneven_wear',
      title: 'Uneven tire wear',
      category: IssueCategory.tyresAndWheels,
    ),
    VehicleIssue(
      id: 'tyre_rim_damage',
      title: 'Bent or damaged rim',
      category: IssueCategory.tyresAndWheels,
    ),
    VehicleIssue(
      id: 'elec_battery',
      title: 'Dead or weak battery',
      category: IssueCategory.electrical,
    ),
    VehicleIssue(
      id: 'elec_alternator',
      title: 'Alternator failure',
      category: IssueCategory.electrical,
    ),
    VehicleIssue(
      id: 'elec_lights',
      title: 'Dim or flickering lights',
      category: IssueCategory.electrical,
    ),
    VehicleIssue(
      id: 'elec_starter',
      title: 'Faulty starter motor',
      category: IssueCategory.electrical,
    ),
    VehicleIssue(
      id: 'elec_fuse',
      title: 'Blown electrical fuse',
      category: IssueCategory.electrical,
    ),
    VehicleIssue(
      id: 'elec_sensors',
      title: 'Malfunctioning sensors',
      category: IssueCategory.electrical,
    ),
  ];

  static List<VehicleIssue> forSpecialization(String specialization) {
    return forSpecializations([specialization]);
  }

  static List<VehicleIssue> forSpecializations(List<String> specializations) {
    final categories = IssueCategory.fromProfileSpecialties(specializations);

    if (categories.isEmpty) {
      return const [];
    }

    return all
        .where((issue) => categories.contains(issue.category))
        .toList(growable: false);
  }

  static List<VehicleIssue> forCategory(IssueCategory category) {
    return all
        .where((issue) => issue.category == category)
        .toList(growable: false);
  }
}
