import 'package:flutter/material.dart';
import 'package:mechfixes/chat/models/chat_enums.dart';
import 'package:mechfixes/chat/models/chat_message.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    if (message.type == ChatMessageType.system ||
        message.senderRole == ChatSenderRole.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              message.text ?? 'System update',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF667085),
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildBubble(context),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.createdAt),
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF98A2B3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    switch (message.type) {
      case ChatMessageType.voice:
        return _voiceBubble();
      case ChatMessageType.location:
        return _locationBubble(context);
      case ChatMessageType.text:
      case ChatMessageType.system:
        return _textBubble();
    }
  }

  Widget _textBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMine ? const Color(0xFF1F3FAF) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isMine ? 14 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 14),
        ),
        border: isMine ? null : Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Text(
        message.text ?? '',
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: isMine ? Colors.white : const Color(0xFF101828),
        ),
      ),
    );
  }

  Widget _voiceBubble() {
    final duration = message.voiceDurationSeconds ?? 0;
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    final durationLabel = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMine ? const Color(0xFF1F3FAF) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isMine ? 14 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 14),
        ),
        border: isMine ? null : Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isMine
                  ? Colors.white.withValues(alpha: 0.18)
                  : const Color(0xFFEAF0FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: isMine ? Colors.white : const Color(0xFF1F3FAF),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 4,
                decoration: BoxDecoration(
                  color: isMine
                      ? Colors.white.withValues(alpha: 0.35)
                      : const Color(0xFFD0D5DD),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.35,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isMine ? Colors.white : const Color(0xFF1F3FAF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                durationLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: isMine ? Colors.white70 : const Color(0xFF667085),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _locationBubble(BuildContext context) {
    return GestureDetector(
      onTap: () => _openMaps(message.latitude, message.longitude),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1F3FAF)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF1F3FAF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.locationLabel ?? 'Shared location',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${message.latitude?.toStringAsFixed(5)}, ${message.longitude?.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to open in Google Maps',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1F3FAF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(double? lat, double? lng) async {
    if (lat == null || lng == null) {
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
