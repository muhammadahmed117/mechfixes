import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mechfixes/data/parsers/firestore_parsers.dart';

/// Firestore document model for `/users/{uid}`.
class UserRecord {
  const UserRecord({
    required this.uid,
    required this.fullName,
    required this.email,
    this.role = 'user',
    this.phone = '',
    this.status = 'active',
    this.isBlocked = false,
    this.adminNote = '',
    this.createdAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final String role;
  final String phone;
  final String status;
  final bool isBlocked;
  final String adminNote;
  final DateTime? createdAt;

  String get displayName =>
      fullName.trim().isNotEmpty ? fullName.trim() : 'Unknown User';

  bool get isActive => !isBlocked && status.toLowerCase() != 'blocked';

  factory UserRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserRecord.fromMap(doc.id, data);
  }

  factory UserRecord.fromMap(String id, Map<String, dynamic> data) {
    final status = FirestoreParsers.readString(
      data['status'],
      fallback: FirestoreParsers.readBool(data['isBlocked']) ? 'blocked' : 'active',
    );

    return UserRecord(
      uid: id,
      fullName: FirestoreParsers.readString(data['fullName']),
      email: FirestoreParsers.readString(data['email']),
      role: FirestoreParsers.readString(data['role'], fallback: 'user'),
      phone: FirestoreParsers.readString(data['phone']),
      status: status,
      isBlocked: FirestoreParsers.readBool(data['isBlocked']) ||
          status.toLowerCase() == 'blocked',
      adminNote: FirestoreParsers.readString(data['adminNote']),
      createdAt: FirestoreParsers.readTimestamp(data['createdAt']),
    );
  }
}
