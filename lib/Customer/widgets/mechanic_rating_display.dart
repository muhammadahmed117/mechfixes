import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

typedef MechanicRatingStats = ({double average, int count});

class MechanicRatingDisplay extends StatelessWidget {
  const MechanicRatingDisplay({
    super.key,
    required this.mechanicId,
    this.starSize = 16,
    this.ratingStyle,
    this.reviewStyle,
    this.showStar = true,
  });

  final String mechanicId;
  final double starSize;
  final TextStyle? ratingStyle;
  final TextStyle? reviewStyle;
  final bool showStar;

  static double readRating(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static MechanicRatingStats statsFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) {
      return (average: 0.0, count: 0);
    }

    var sum = 0.0;
    for (final doc in docs) {
      sum += readRating(doc.data()['rating']);
    }

    return (average: sum / docs.length, count: docs.length);
  }

  static Stream<MechanicRatingStats> ratingStream(String mechanicId) {
    if (mechanicId.trim().isEmpty) {
      return Stream.value((average: 0.0, count: 0));
    }

    return FirebaseFirestore.instance
        .collection('reviews')
        .where('mechanicId', isEqualTo: mechanicId)
        .snapshots()
        .map((snapshot) => statsFromDocs(snapshot.docs));
  }

  static String reviewLabel(int count) {
    return count == 1 ? '1 review' : '$count reviews';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MechanicRatingStats>(
      stream: ratingStream(mechanicId),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? (average: 0.0, count: 0);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showStar) ...[
              Icon(Icons.star, color: Colors.amber, size: starSize),
              const SizedBox(width: 4),
            ],
            Text(
              stats.average.toStringAsFixed(1),
              style: ratingStyle ??
                  const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF101828),
                  ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '(${reviewLabel(stats.count)})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: reviewStyle ??
                    const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF667085),
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}
