import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mechfixes/Customer/issue_category.dart';
import 'package:mechfixes/data/parsers/firestore_parsers.dart';

/// Firestore document model for `/mechanics/{uid}`.
class MechanicRecord {
  const MechanicRecord({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.shopName,
    required this.phone,
    required this.address,
    required this.specialties,
    required this.isVerified,
    required this.isDemo,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.rating = 0,
    this.reviewCount = 0,
    this.selectedSkills = const [],
    this.openingDays = '',
    this.openingHours = '',
    this.status = 'pending',
    this.createdAt,
  });

  final String uid;
  final String email;
  final String fullName;
  final String shopName;
  final String phone;
  final String address;
  final List<String> specialties;
  final bool isVerified;
  final bool isDemo;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final List<String> selectedSkills;
  final String openingDays;
  final String openingHours;
  final String status;
  final DateTime? createdAt;

  String get displayName => shopName.trim().isNotEmpty ? shopName : fullName;

  List<IssueCategory> get issueCategories =>
      IssueCategory.fromProfileSpecialties(specialties);

  factory MechanicRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return MechanicRecord(
      uid: doc.id,
      email: FirestoreParsers.readString(data['email']),
      fullName: FirestoreParsers.readString(data['fullName']),
      shopName: FirestoreParsers.readString(data['shopName']),
      phone: FirestoreParsers.readString(data['phone']),
      address: _readAddress(data),
      specialties: FirestoreParsers.readStringList(data['specialties']),
      isVerified: FirestoreParsers.readBool(data['isVerified']),
      isDemo: FirestoreParsers.readBool(data['isDemo']),
      latitude: _readLatitude(data),
      longitude: _readLongitude(data),
      imageUrl: () {
        final url = FirestoreParsers.readString(data['imageUrl']);
        return url.isEmpty ? null : url;
      }(),
      rating: FirestoreParsers.readDouble(data['rating']),
      reviewCount: FirestoreParsers.readInt(data['reviewCount']),
      selectedSkills: FirestoreParsers.readStringList(data['selectedSkills']),
      openingDays: _readOpeningDays(data),
      openingHours: _readOpeningHours(data),
      status: FirestoreParsers.readString(data['status'], fallback: 'pending'),
      createdAt: FirestoreParsers.readTimestamp(data['createdAt']),
    );
  }

  static String _readAddress(Map<String, dynamic> data) {
    final location = FirestoreParsers.readString(data['location']);
    if (location.isNotEmpty) return location;
    return FirestoreParsers.readString(data['address']);
  }

  bool get isRejected => status.toLowerCase() == 'rejected';

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get hasCompleteProfile =>
      shopName.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      address.trim().isNotEmpty;

  /// Customer-visible mechanics must not be demo data and need a complete profile.
  /// Verified mechanics are always shown. Mechanics with existing reviews are also
  /// shown so a profile edit does not hide previously approved shops.
  bool get isCustomerVisible =>
      !isDemo &&
      !isRejected &&
      hasCompleteProfile &&
      (isVerified || reviewCount > 0);

  Map<String, dynamic> toFirestore({bool includeDefaults = false}) {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'shopName': shopName,
      'phone': phone,
      'address': address,
      'specialties': specialties,
      'selectedSkills': selectedSkills,
      'isVerified': isVerified,
      'isDemo': isDemo,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      if (includeDefaults) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Maps to the legacy `Map` shape used by customer UI widgets.
  Map<String, dynamic> toDisplayMap({double distanceValue = 999}) {
    final categories = issueCategories;

    return {
      'id': uid,
      'name': displayName,
      'rating': rating.toStringAsFixed(1),
      'reviews': '$reviewCount reviews',
      'distance': distanceValue >= 999 ? '—' : '${distanceValue.toStringAsFixed(1)} miles',
      'distanceValue': distanceValue,
      'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'phone': phone,
      'specialties': categories,
      'specialty': IssueCategory.formatLabels(categories),
      if (imageUrl != null) 'image': imageUrl,
      'openingDays': openingDays,
      'openingHours': openingHours,
      'services': specialties,
    };
  }

  static String _readOpeningDays(Map<String, dynamic> data) {
    final combined = FirestoreParsers.readString(data['openingDays']);
    if (combined.isNotEmpty) return combined;

    final start = FirestoreParsers.readString(data['openingDayStart']);
    final end = FirestoreParsers.readString(data['openingDayEnd']);
    if (start.isEmpty && end.isEmpty) return '';
    if (end.isEmpty) return start;
    return '$start-$end';
  }

  static String _readOpeningHours(Map<String, dynamic> data) {
    final combined = FirestoreParsers.readString(data['openingHours']);
    if (combined.isNotEmpty) return combined;

    final start = FirestoreParsers.readString(data['openingHourStart']);
    final end = FirestoreParsers.readString(data['openingHourEnd']);
    if (start.isEmpty && end.isEmpty) return '';
    if (end.isEmpty) return start;
    return '$start - $end';
  }

  static double? _readLatitude(Map<String, dynamic> data) {
    try {
      final geoPoint = data['geoPoint'];
      if (geoPoint is GeoPoint) return geoPoint.latitude;
      if (geoPoint is Map) {
        final value = geoPoint['latitude'] ?? geoPoint['_latitude'];
        if (value is num) return value.toDouble();
      }

      final latitude = data['latitude'];
      if (latitude is num) return latitude.toDouble();
    } catch (_) {
      return null;
    }
    return null;
  }

  static double? _readLongitude(Map<String, dynamic> data) {
    try {
      final geoPoint = data['geoPoint'];
      if (geoPoint is GeoPoint) return geoPoint.longitude;
      if (geoPoint is Map) {
        final value = geoPoint['longitude'] ?? geoPoint['_longitude'];
        if (value is num) return value.toDouble();
      }

      final longitude = data['longitude'];
      if (longitude is num) return longitude.toDouble();
    } catch (_) {
      return null;
    }
    return null;
  }
}
