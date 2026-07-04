import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mechfixes/chat/models/chat_enums.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.type,
    required this.createdAt,
    this.text,
    this.voiceUrl,
    this.voiceDurationSeconds,
    this.latitude,
    this.longitude,
    this.locationLabel,
    this.systemEvent,
  });

  final String id;
  final String senderId;
  final ChatSenderRole senderRole;
  final ChatMessageType type;
  final DateTime createdAt;
  final String? text;
  final String? voiceUrl;
  final int? voiceDurationSeconds;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final ChatSystemEvent? systemEvent;

  bool get isMine => senderRole != ChatSenderRole.system;

  factory ChatMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderRole: ChatSenderRoleX.fromFirestore(data['senderRole'] as String?),
      type: ChatMessageTypeX.fromFirestore(data['type'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      text: data['text'] as String?,
      voiceUrl: data['voiceUrl'] as String?,
      voiceDurationSeconds: data['voiceDurationSeconds'] as int?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      locationLabel: data['locationLabel'] as String?,
      systemEvent:
          ChatSystemEventX.fromFirestore(data['systemEvent'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderRole': senderRole.firestoreValue,
      'type': type.firestoreValue,
      'text': text,
      'voiceUrl': voiceUrl,
      'voiceDurationSeconds': voiceDurationSeconds,
      'latitude': latitude,
      'longitude': longitude,
      'locationLabel': locationLabel,
      'systemEvent': systemEvent?.firestoreValue,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.customerId,
    required this.mechanicId,
    required this.customerName,
    required this.mechanicName,
    required this.locationRequestStatus,
    this.pendingLocationRequestId,
    this.lastMessage,
    this.updatedAt,
  });

  final String id;
  final String customerId;
  final String mechanicId;
  final String customerName;
  final String mechanicName;
  final LocationRequestStatus locationRequestStatus;
  final String? pendingLocationRequestId;
  final String? lastMessage;
  final DateTime? updatedAt;

  factory ChatRoom.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return ChatRoom(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      mechanicId: data['mechanicId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Customer',
      mechanicName: data['mechanicName'] as String? ?? 'Mechanic',
      locationRequestStatus: LocationRequestStatusX.fromFirestore(
        data['locationRequestStatus'] as String?,
      ),
      pendingLocationRequestId:
          data['pendingLocationRequestId'] as String?,
      lastMessage: data['lastMessage'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
