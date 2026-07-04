import 'package:flutter/material.dart';
import 'package:mechfixes/Customer/mechanic_map_screen.dart';
import 'package:mechfixes/chat/screens/chat_screen.dart';

Future<void> showContactMechanicSheet({
  required BuildContext context,
  required String mechanicId,
  required String mechanicName,
  required String mechanicAddress,
  double? destinationLatitude,
  double? destinationLongitude,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D5DD),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                mechanicName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'How would you like to connect?',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 18),
              _ContactOptionCard(
                icon: Icons.navigation_outlined,
                title: 'Visit Mechanic',
                subtitle: 'Get turn-by-turn directions to the shop',
                accentColor: const Color(0xFF1F3FAF),
                onTap: () {
                  Navigator.pop(sheetContext);
                  MechanicMapScreen.open(
                    context,
                    mechanicName: mechanicName,
                    address: mechanicAddress,
                    latitude: destinationLatitude,
                    longitude: destinationLongitude,
                  );
                },
              ),
              const SizedBox(height: 12),
              _ContactOptionCard(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Call Mechanic to My Location',
                subtitle: 'Open a live chat and share your location',
                accentColor: const Color(0xFF12B76A),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverId: mechanicId,
                        receiverName: mechanicName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ContactOptionCard extends StatelessWidget {
  const _ContactOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD0D5DD)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF98A2B3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
