import 'package:mechfixes/Customer/issue_category.dart';

class MechanicsData {
  static List<Map<String, dynamic>> get all => List.unmodifiable(_mechanics);

  static List<Map<String, dynamic>> forCategory(IssueCategory? category) {
    if (category == null) {
      return all;
    }

    return _mechanics
        .where(
          (mechanic) => IssueCategory.matchesFilter(
            List<IssueCategory>.from(mechanic['specialties'] as List),
            category,
          ),
        )
        .toList();
  }

  static final List<Map<String, dynamic>> _mechanics = [
    {
      "id": "mechanic_elite_auto",
      "name": "Elite Auto Service",
      "rating": "4.9",
      "reviews": "245 reviews",
      "distance": "0.8 miles",
      "distanceValue": 0.8,
      "address": "123 Main St, San Francisco",
      "latitude": 37.7749,
      "longitude": -122.4194,
      "phone": "+1 234 567 8900",
      "specialties": [
        IssueCategory.mechanical,
        IssueCategory.electrical,
        IssueCategory.tyresAndWheels,
      ],
      "specialty": IssueCategory.formatLabels([
        IssueCategory.mechanical,
        IssueCategory.electrical,
        IssueCategory.tyresAndWheels,
      ]),
      "image":
          "https://images.unsplash.com/photo-1487754180451-c456f719a1fc?auto=format&fit=crop&w=900&q=80",
    },
    {
      "id": "mechanic_precision_motors",
      "name": "Precision Motors",
      "rating": "4.8",
      "reviews": "189 reviews",
      "distance": "1.3 miles",
      "distanceValue": 1.3,
      "address": "456 Oak Ave, San Francisco",
      "latitude": 37.7849,
      "longitude": -122.4094,
      "phone": "+1 234 567 8901",
      "specialties": [IssueCategory.mechanical],
      "specialty": IssueCategory.formatLabels([IssueCategory.mechanical]),
      "image":
          "https://images.unsplash.com/photo-1517524008697-84bbe3c3fd98?auto=format&fit=crop&w=900&q=80",
    },
    {
      "name": "QuickFix Auto",
      "rating": "4.7",
      "reviews": "156 reviews",
      "distance": "2.1 miles",
      "distanceValue": 2.1,
      "address": "789 Elm St, San Francisco",
      "specialties": [IssueCategory.tyresAndWheels],
      "specialty":
          IssueCategory.formatLabels([IssueCategory.tyresAndWheels]),
      "image":
          "https://images.unsplash.com/photo-1517524008697-84bbe3c3fd98?auto=format&fit=crop&w=900&q=80",
    },
    {
      "name": "Master Tech Auto",
      "rating": "4.9",
      "reviews": "312 reviews",
      "distance": "2.7 miles",
      "distanceValue": 2.7,
      "address": "321 Pine Rd, San Francisco",
      "specialties": [
        IssueCategory.mechanical,
        IssueCategory.electrical,
      ],
      "specialty": IssueCategory.formatLabels([
        IssueCategory.mechanical,
        IssueCategory.electrical,
      ]),
      "image":
          "https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=900&q=80",
    },
    {
      "name": "SparkLine Electrics",
      "rating": "4.6",
      "reviews": "98 reviews",
      "distance": "3.0 miles",
      "distanceValue": 3.0,
      "address": "88 Battery Ln, San Francisco",
      "specialties": [IssueCategory.electrical],
      "specialty": IssueCategory.formatLabels([IssueCategory.electrical]),
      "image":
          "https://images.unsplash.com/photo-1625047509248-ec889cbff753?auto=format&fit=crop&w=900&q=80",
    },
    {
      "name": "WheelPro Garage",
      "rating": "4.8",
      "reviews": "142 reviews",
      "distance": "1.9 miles",
      "distanceValue": 1.9,
      "address": "55 Rim Rd, San Francisco",
      "specialties": [
        IssueCategory.tyresAndWheels,
        IssueCategory.mechanical,
      ],
      "specialty": IssueCategory.formatLabels([
        IssueCategory.tyresAndWheels,
        IssueCategory.mechanical,
      ]),
      "image":
          "https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?auto=format&fit=crop&w=900&q=80",
    },
  ];
}
