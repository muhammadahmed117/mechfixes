import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mechfixes/chat/models/chat_enums.dart';
import 'package:mechfixes/chat/models/chat_message.dart';

/// Firestore schema
/// ---------------
/// /chats/{chatId}
///   customerId: string
///   mechanicId: string
///   customerName: string
///   mechanicName: string
///   lastMessage: string
///   lastMessageAt: timestamp
///   updatedAt: timestamp
///   locationRequestStatus: 'none' | 'pending' | 'granted' | 'denied'
///   pendingLocationRequestId: string | null
///
/// /chats/{chatId}/messages/{messageId}
///   senderId: string
///   senderRole: 'customer' | 'mechanic' | 'system'
///   type: 'text' | 'voice' | 'location' | 'system'
///   text: string | null
///   voiceUrl: string | null
///   voiceDurationSeconds: number | null
///   latitude: number | null
///   longitude: number | null
///   locationLabel: string | null
///   systemEvent: 'location_request' | 'location_granted' | 'location_denied' | 'location_declined' | null
///   createdAt: timestamp
class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  static bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String buildChatId({
    required String customerId,
    required String mechanicId,
  }) {
    return '${customerId}__$mechanicId';
  }

  DocumentReference<Map<String, dynamic>> _chatRef(String chatId) {
    return _db.collection('chats').doc(chatId);
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(String chatId) {
    return _chatRef(chatId).collection('messages');
  }

  Future<void> ensureChatRoom({
    required String chatId,
    required String customerId,
    required String mechanicId,
    required String customerName,
    required String mechanicName,
  }) async {
    if (!isFirebaseReady) {
      return;
    }

    final chatRef = _chatRef(chatId);
    final snapshot = await chatRef.get();

    if (!snapshot.exists) {
      await chatRef.set({
        'customerId': customerId,
        'mechanicId': mechanicId,
        'customerName': customerName,
        'mechanicName': mechanicName,
        'lastMessage': '',
        'locationRequestStatus': LocationRequestStatus.none.firestoreValue,
        'pendingLocationRequestId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<ChatRoom?> watchChatRoom(String chatId) {
    if (!isFirebaseReady) {
      return Stream.value(null);
    }

    return _chatRef(chatId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }

      return ChatRoom.fromFirestore(doc);
    });
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    if (!isFirebaseReady) {
      return Stream.value(const []);
    }

    return _messagesRef(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ChatMessage.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required ChatSenderRole senderRole,
    required String text,
  }) async {
    if (!isFirebaseReady) {
      return;
    }

    await _messagesRef(chatId).add({
      'senderId': senderId,
      'senderRole': senderRole.firestoreValue,
      'type': ChatMessageType.text.firestoreValue,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _chatRef(chatId).update({
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendVoicePlaceholder({
    required String chatId,
    required String senderId,
    required ChatSenderRole senderRole,
  }) async {
    if (!isFirebaseReady) {
      return;
    }

    const placeholderDuration = 12;

    await _messagesRef(chatId).add({
      'senderId': senderId,
      'senderRole': senderRole.firestoreValue,
      'type': ChatMessageType.voice.firestoreValue,
      'voiceUrl': null,
      'voiceDurationSeconds': placeholderDuration,
      'text': 'Voice message',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _chatRef(chatId).update({
      'lastMessage': 'Voice message',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> requestCustomerLocation({
    required String chatId,
    required String mechanicId,
  }) async {
    if (!isFirebaseReady) {
      return;
    }

    final messageRef = await _messagesRef(chatId).add({
      'senderId': mechanicId,
      'senderRole': ChatSenderRole.system.firestoreValue,
      'type': ChatMessageType.system.firestoreValue,
      'text': 'Mechanic requested your location.',
      'systemEvent': ChatSystemEvent.locationRequest.firestoreValue,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _chatRef(chatId).update({
      'locationRequestStatus': LocationRequestStatus.pending.firestoreValue,
      'pendingLocationRequestId': messageRef.id,
      'lastMessage': 'Location request sent',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> shareCustomerLocation({
    required String chatId,
    required String customerId,
    required double latitude,
    required double longitude,
    String? locationLabel,
  }) async {
    if (!isFirebaseReady) {
      return;
    }

    await _messagesRef(chatId).add({
      'senderId': customerId,
      'senderRole': ChatSenderRole.customer.firestoreValue,
      'type': ChatMessageType.location.firestoreValue,
      'latitude': latitude,
      'longitude': longitude,
      'locationLabel': locationLabel ?? 'Shared location',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _messagesRef(chatId).add({
      'senderId': 'system',
      'senderRole': ChatSenderRole.system.firestoreValue,
      'type': ChatMessageType.system.firestoreValue,
      'text': 'Customer shared their location.',
      'systemEvent': ChatSystemEvent.locationGranted.firestoreValue,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _chatRef(chatId).update({
      'locationRequestStatus': LocationRequestStatus.granted.firestoreValue,
      'pendingLocationRequestId': null,
      'lastMessage': 'Location shared',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> declineLocationShare({
    required String chatId,
  }) async {
    if (!isFirebaseReady) {
      return;
    }

    await _messagesRef(chatId).add({
      'senderId': 'system',
      'senderRole': ChatSenderRole.system.firestoreValue,
      'type': ChatMessageType.system.firestoreValue,
      'text': 'User declined to share location.',
      'systemEvent': ChatSystemEvent.locationDeclined.firestoreValue,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _chatRef(chatId).update({
      'locationRequestStatus': LocationRequestStatus.denied.firestoreValue,
      'pendingLocationRequestId': null,
      'lastMessage': 'User declined to share location.',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}
