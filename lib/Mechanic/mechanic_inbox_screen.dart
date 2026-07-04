import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mechfixes/chat/screens/chat_screen.dart';

class MechanicInboxScreen extends StatelessWidget {
  const MechanicInboxScreen({super.key});

  String _resolveReceiverName(
    dynamic participantNames,
    String receiverId,
  ) {
    if (participantNames is Map) {
      final direct = participantNames[receiverId];
      if (direct is String && direct.trim().isNotEmpty) {
        return direct.trim();
      }
    }

    if (participantNames is List) {
      for (final name in participantNames) {
        if (name is String && name.trim().isNotEmpty) {
          return name.trim();
        }
      }
    }

    return 'Customer';
  }

  String _formatLastMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(targetDay).inDays;

    if (difference == 0) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212936),
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3B82F6),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 46,
                    color: Color(0xFF98A2B3),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No messages yet.',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snapshot.data?.docs ?? [],
          );

          docs.sort((a, b) {
            final aTime = a.data()['lastMessageTime'];
            final bTime = b.data()['lastMessageTime'];
            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }
            return 0;
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 46,
                    color: Color(0xFF98A2B3),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No messages yet.',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final participants =
                  (data['participants'] as List<dynamic>? ?? const [])
                      .map((e) => e.toString())
                      .toList();

              final receiverId = participants.firstWhere(
                (id) => id != currentUid,
                orElse: () => '',
              );

              final receiverName = _resolveReceiverName(
                data['participantNames'],
                receiverId,
              );

              final lastMessage =
                  (data['lastMessage'] as String?)?.trim().isNotEmpty == true
                      ? data['lastMessage'] as String
                      : 'No messages yet';

              final lastMessageTime =
                  data['lastMessageTime'] as Timestamp?;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE4E7EF)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8EDF8),
                    child: Text(
                      receiverName.isNotEmpty
                          ? receiverName[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: Color(0xFF1F3FAF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    receiverName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101828),
                    ),
                  ),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 13,
                    ),
                  ),
                  trailing: Text(
                    _formatLastMessageTime(lastMessageTime),
                    style: const TextStyle(
                      color: Color(0xFF98A2B3),
                      fontSize: 12,
                    ),
                  ),
                  onTap: receiverId.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                receiverId: receiverId,
                                receiverName: receiverName,
                              ),
                            ),
                          );
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
