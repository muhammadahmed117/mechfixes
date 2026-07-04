enum IssueCategory {
  mechanical,
  tyresAndWheels,
  electrical;

  String get label {
    switch (this) {
      case IssueCategory.mechanical:
        return 'Mechanical';
      case IssueCategory.tyresAndWheels:
        return 'Tyres & Wheels';
      case IssueCategory.electrical:
        return 'Electrical';
    }
  }

  static IssueCategory? fromProfileSpecialty(String specialty) {
    final normalized = specialty.trim().toLowerCase();

    if (normalized.contains('machinal') ||
        normalized.contains('mechanical') ||
        normalized.contains('engine') ||
        normalized.contains('transmission')) {
      return IssueCategory.mechanical;
    }

    if (normalized.contains('tyre') ||
        normalized.contains('tire') ||
        normalized.contains('wheel')) {
      return IssueCategory.tyresAndWheels;
    }

    if (normalized.contains('electrical') ||
        normalized.contains('electric')) {
      return IssueCategory.electrical;
    }

    return null;
  }

  static List<IssueCategory> fromProfileSpecialties(List<String> specialties) {
    final categories = <IssueCategory>{};

    for (final specialty in specialties) {
      final category = fromProfileSpecialty(specialty);
      if (category != null) {
        categories.add(category);
      }
    }

    return categories.toList();
  }

  static String formatLabels(List<IssueCategory> categories) {
    return categories.map((category) => category.label).join(' · ');
  }

  static bool matchesFilter(
    List<IssueCategory> mechanicSpecialties,
    IssueCategory? filter,
  ) {
    if (filter == null) {
      return true;
    }

    return mechanicSpecialties.contains(filter);
  }
}
