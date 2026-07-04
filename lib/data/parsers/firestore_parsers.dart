import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Shared null-safe Firestore field parsers.
class FirestoreParsers {
  FirestoreParsers._();

  static String readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static bool readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
      return fallback;
    }
    if (value is num) return value != 0;
    return fallback;
  }

  static double readDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static DateTime? readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static List<String> readStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const [];
  }

  static List<T> parseDocs<T>(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    T Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) parse, {
    required String logLabel,
  }) {
    final results = <T>[];
    var failures = 0;

    for (final doc in docs) {
      try {
        results.add(parse(doc));
      } catch (error, stackTrace) {
        failures++;
        debugPrint('[$logLabel] Skipped document ${doc.id}: $error');
        debugPrint('$stackTrace');
      }
    }

    debugPrint(
      '[$logLabel] Loaded ${results.length}/${docs.length} documents '
      '(failures: $failures)',
    );

    return results;
  }
}
