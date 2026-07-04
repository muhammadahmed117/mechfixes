import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:mechfixes/Customer/issue_category.dart';
import 'package:mechfixes/data/models/mechanic_record.dart';
import 'package:mechfixes/services/mechanic_auth_service.dart';

/// Reads customer-visible mechanics from Firestore.
class MechanicsRepository {
  MechanicsRepository._();

  static final MechanicsRepository instance = MechanicsRepository._();

  static bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Live stream of mechanics visible to customers.
  Stream<List<MechanicRecord>> watchVerifiedMechanics() {
    if (!isFirebaseReady) {
      debugPrint('[MechanicsRepository] Firebase not ready, returning empty list');
      return Stream.value(const []);
    }

    return _mechanicsQuery().snapshots().map(_mapSnapshotToRecords);
  }

  /// One-time fetch of mechanics visible to customers.
  Future<List<MechanicRecord>> fetchVerifiedMechanics() async {
    if (!isFirebaseReady) {
      debugPrint('[MechanicsRepository] Firebase not ready, returning empty list');
      return const [];
    }

    final snapshot = await _mechanicsQuery().get();
    return _mapSnapshotToRecords(snapshot);
  }

  /// Customer-facing list filtered by issue category and mapped for UI cards.
  Stream<List<Map<String, dynamic>>> watchDisplayMechanics({
    IssueCategory? category,
  }) {
    return watchVerifiedMechanics().map((records) {
      final displayList = _toDisplayList(records, category);
      debugPrint(
        '[MechanicsRepository] Display mechanics after category filter '
        '(${category?.label ?? 'all'}): ${displayList.length}',
      );
      return displayList;
    });
  }

  Future<List<Map<String, dynamic>>> fetchDisplayMechanics({
    IssueCategory? category,
  }) async {
    final records = await fetchVerifiedMechanics();
    return _toDisplayList(records, category);
  }

  Query<Map<String, dynamic>> _mechanicsQuery() {
    return _db.collection(MechanicAuthService.mechanicsCollection);
  }

  List<MechanicRecord> _mapSnapshotToRecords(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    debugPrint(
      '[MechanicsRepository] Fetched ${snapshot.docs.length} mechanic documents from Firestore',
    );

    final records = <MechanicRecord>[];
    var parseFailures = 0;
    var demoFiltered = 0;
    var incompleteFiltered = 0;
    var hiddenUnverified = 0;

    for (final doc in snapshot.docs) {
      try {
        final record = MechanicRecord.fromFirestore(doc);
        if (!record.isCustomerVisible) {
          if (record.isDemo) {
            demoFiltered++;
          } else if (!record.hasCompleteProfile) {
            incompleteFiltered++;
            debugPrint(
              '[MechanicsRepository] Hidden incomplete mechanic ${doc.id} '
              '(shop: "${record.shopName}", phone: "${record.phone}")',
            );
          } else if (!record.isVerified) {
            hiddenUnverified++;
            debugPrint(
              '[MechanicsRepository] Hidden unverified mechanic ${doc.id}',
            );
          }
          continue;
        }

        records.add(record);
      } catch (error, stackTrace) {
        parseFailures++;
        debugPrint(
          '[MechanicsRepository] Skipped mechanic ${doc.id} due to parse error: $error',
        );
        debugPrint('$stackTrace');
      }
    }

    final withoutCoordinates =
        records.where((record) => !record.hasCoordinates).length;
    debugPrint(
      '[MechanicsRepository] Returning ${records.length} customer-visible mechanics '
      '(demo: $demoFiltered, incomplete: $incompleteFiltered, '
      'unverified: $hiddenUnverified, parse failures: $parseFailures, '
      'without coordinates: $withoutCoordinates)',
    );

    return records;
  }

  List<Map<String, dynamic>> _toDisplayList(
    List<MechanicRecord> records,
    IssueCategory? category,
  ) {
    final beforeCategoryCount = records.length;
    final filtered = category == null
        ? records
        : records
            .where(
              (record) => IssueCategory.matchesFilter(
                record.issueCategories,
                category,
              ),
            )
            .toList();

    if (category != null) {
      debugPrint(
        '[MechanicsRepository] Category filter removed '
        '${beforeCategoryCount - filtered.length} of $beforeCategoryCount mechanics',
      );
    }

    return filtered
        .map((record) => record.toDisplayMap())
        .toList(growable: false);
  }
}
