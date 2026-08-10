import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mechfixes/data/parsers/firestore_parsers.dart';

/// Firestore document model for `/complaints/{id}`.
class ComplaintRecord {
  const ComplaintRecord({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.mechanicName,
    required this.issue,
    required this.status,
    this.adminNote = '',
    this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String userName;
  final String userEmail;
  final String mechanicName;
  final String issue;
  final String status;
  final String adminNote;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  bool get isOpen => status.toLowerCase() != 'resolved';
  bool get isResolved => status.toLowerCase() == 'resolved';

  factory ComplaintRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return ComplaintRecord.fromMap(doc.id, data);
  }

  factory ComplaintRecord.fromMap(String id, Map<String, dynamic> data) {
    return ComplaintRecord(
      id: id,
      userName: FirestoreParsers.readString(
        data['userName'],
        fallback: 'Unknown User',
      ),
      userEmail: FirestoreParsers.readString(data['userEmail']),
      mechanicName: FirestoreParsers.readString(
        data['mechanicName'],
        fallback: 'Unknown Mechanic',
      ),
      issue: FirestoreParsers.readString(
        data['issue'],
        fallback: 'No details provided',
      ),
      status: FirestoreParsers.readString(
        data['status'],
        fallback: 'open',
      ),
      adminNote: FirestoreParsers.readString(data['adminNote']),
      createdAt: FirestoreParsers.readTimestamp(data['createdAt']),
      resolvedAt: FirestoreParsers.readTimestamp(data['resolvedAt']),
    );
  }
}
