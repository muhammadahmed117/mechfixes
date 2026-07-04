import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Saves mechanic skill selections to Firestore.
///
/// /mechanics/{mechanicId}
///   selectedSkills: string[]
///   skillsUpdatedAt: timestamp
class MechanicSkillsService {
  MechanicSkillsService._();

  static final MechanicSkillsService instance = MechanicSkillsService._();

  static bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> saveSelectedSkills({
    required String mechanicId,
    required List<String> selectedSkills,
  }) async {
    if (!isFirebaseReady) {
      return;
    }

    await _db.collection('mechanics').doc(mechanicId).set(
      {
        'selectedSkills': selectedSkills,
        'skillsUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<String>> watchSelectedSkills(String mechanicId) {
    if (!isFirebaseReady) {
      return Stream.value(const []);
    }

    return _db.collection('mechanics').doc(mechanicId).snapshots().map((doc) {
      final skills = doc.data()?['selectedSkills'];
      if (skills is List) {
        return skills.map((item) => item.toString()).toList(growable: false);
      }
      return const [];
    });
  }
}
