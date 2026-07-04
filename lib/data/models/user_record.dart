import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mechfixes/data/parsers/firestore_parsers.dart';

/// Firestore document model for `/users/{uid}`.
class UserRecord {
  const UserRecord({
    required this.uid,
    required this.fullName,
    required this.email,
    this.createdAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final DateTime? createdAt;

  String get displayName =>
      fullName.trim().isNotEmpty ? fullName.trim() : 'Unknown User';

  factory UserRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return UserRecord(
      uid: doc.id,
      fullName: FirestoreParsers.readString(data['fullName']),
      email: FirestoreParsers.readString(data['email']),
      createdAt: FirestoreParsers.readTimestamp(data['createdAt']),
    );
  }

  factory UserRecord.fromMap(String id, Map<String, dynamic> data) {
    return UserRecord(
      uid: id,
      fullName: FirestoreParsers.readString(data['fullName']),
      email: FirestoreParsers.readString(data['email']),
      createdAt: FirestoreParsers.readTimestamp(data['createdAt']),
    );
  }
}
