import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mechfixes/Customer/widgets/mechanic_rating_display.dart';

class RatingsReviewsScreen extends StatefulWidget {
  const RatingsReviewsScreen({
    super.key,
    required this.mechanicId,
    this.mechanicName = 'Mechanic',
  });

  final String mechanicId;
  final String mechanicName;

  @override
  State<RatingsReviewsScreen> createState() => _RatingsReviewsScreenState();
}

class _RatingsReviewsScreenState extends State<RatingsReviewsScreen> {
  int selectedRating = 0;
  bool _isSubmitting = false;
  bool _hasSubmittedReview = false;
  final TextEditingController reviewController = TextEditingController();

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _reviewsStream() {
    return FirebaseFirestore.instance
        .collection('reviews')
        .where('mechanicId', isEqualTo: widget.mechanicId)
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortedDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final sorted =
        List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
    sorted.sort((a, b) {
      final aTime = a.data()['createdAt'];
      final bTime = b.data()['createdAt'];
      if (aTime is Timestamp && bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }
      return 0;
    });
    return sorted;
  }

  double _readRating(dynamic value) => MechanicRatingDisplay.readRating(value);

  String _formatDate(dynamic createdAt) {
    if (createdAt is! Timestamp) return '—';
    final date = createdAt.toDate();
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  ({
    double averageRating,
    int totalReviews,
    List<Map<String, dynamic>> ratingBreakdown,
  }) _calculateStats(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final liveStats = MechanicRatingDisplay.statsFromDocs(docs);
    final totalReviews = liveStats.count;
    final averageRating = liveStats.average;

    final starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    if (totalReviews > 0) {
      for (final doc in docs) {
        final rating = _readRating(doc.data()['rating']).round().clamp(1, 5);
        starCounts[rating] = (starCounts[rating] ?? 0) + 1;
      }
    }

    final ratingBreakdown = [5, 4, 3, 2, 1].map((stars) {
      final count = starCounts[stars] ?? 0;
      final percent =
          totalReviews > 0 ? count / totalReviews : 0.0;
      return {'stars': stars, 'percent': percent};
    }).toList();

    return (
      averageRating: averageRating,
      totalReviews: totalReviews,
      ratingBreakdown: ratingBreakdown,
    );
  }

  Future<void> _submitReview() async {
    if (selectedRating <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to submit a review')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      String currentUserName = user.displayName?.trim() ?? '';
      if (currentUserName.isEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        currentUserName =
            userDoc.data()?['fullName'] as String? ?? 'User';
      }

      await FirebaseFirestore.instance.collection('reviews').add({
        'mechanicId': widget.mechanicId,
        'userId': user.uid,
        'userName': currentUserName,
        'rating': selectedRating,
        'reviewText': reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final reviewsSnap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('mechanicId', isEqualTo: widget.mechanicId)
          .get();

      double sum = 0;
      for (final doc in reviewsSnap.docs) {
        sum += _readRating(doc.data()['rating']);
      }
      final count = reviewsSnap.docs.length;
      final avg = count > 0 ? sum / count : 0.0;

      await FirebaseFirestore.instance
          .collection('mechanics')
          .doc(widget.mechanicId)
          .update({
        'rating': avg,
        'reviewCount': count,
      });

      reviewController.clear();
      setState(() {
        selectedRating = 0;
        _hasSubmittedReview = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully'),
          backgroundColor: Color(0xFF1FAB5D),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 60,
              color: const Color(0xFF1F3FAF),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios, color: Colors.white, size: 15),
                        SizedBox(width: 4),
                        Text(
                          "Back",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "Ratings & Reviews",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _reviewsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1F3FAF),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load reviews.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ),
                    );
                  }

                  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                      snapshot.hasData
                          ? _sortedDocs(snapshot.data!.docs)
                          : <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                  final stats = _calculateStats(docs);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewCard(
                          mechanicName: widget.mechanicName,
                          averageRating: stats.averageRating,
                          totalReviews: stats.totalReviews,
                          ratingBreakdown: stats.ratingBreakdown,
                        ),
                        const SizedBox(height: 12),
                        _buildWriteReviewCard(),
                        const SizedBox(height: 12),
                        const Text(
                          "Customer Reviews",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF475467),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (docs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No reviews yet',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF98A2B3),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data();
                              final userName =
                                  data['userName'] as String? ?? 'Customer';
                              final initial = userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : '?';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildReviewCard(
                                  name: userName,
                                  date: _formatDate(data['createdAt']),
                                  rating: _readRating(data['rating']).round(),
                                  text: data['reviewText'] as String? ?? '',
                                  helpful: data['helpful'] as int? ?? 0,
                                  initial: initial,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String mechanicName,
    required double averageRating,
    required int totalReviews,
    required List<Map<String, dynamic>> ratingBreakdown,
  }) {
    final displayRating = averageRating.toStringAsFixed(1);
    final filledStars = averageRating.round().clamp(0, 5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mechanicName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  displayRating,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF101828),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      color: index < filledStars
                          ? const Color(0xFFF4B400)
                          : const Color(0xFFD0D5DD),
                      size: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalReviews reviews',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: ratingBreakdown.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        child: Text(
                          "${item["stars"]} ★",
                          style: const TextStyle(
                            fontSize: 8,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: item["percent"] as double,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFE4E7EC),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFFF4B400),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 26,
                        child: Text(
                          "${((item["percent"] as double) * 100).toInt()}%",
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Color(0xFF98A2B3),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteReviewCard() {
    if (_hasSubmittedReview) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD0D5DD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF1FAB5D),
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Review submitted',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Thanks for sharing your feedback. Your review is now visible below.',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF667085),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  setState(() => _hasSubmittedReview = false);
                },
                child: const Text('Write another review'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Write a Review",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Your Rating",
            style: TextStyle(
              fontSize: 8,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return GestureDetector(
                onTap: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          selectedRating = starIndex;
                        });
                      },
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.star,
                    size: 18,
                    color: starIndex <= selectedRating
                        ? const Color(0xFFF4B400)
                        : const Color(0xFFD0D5DD),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          const Text(
            "Your Review",
            style: TextStyle(
              fontSize: 8,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: reviewController,
            maxLines: 3,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              hintText: "Share your experience with this mechanic...",
              hintStyle: const TextStyle(
                fontSize: 9,
                color: Color(0xFF98A2B3),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF1F3FAF)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F3FAF),
                disabledBackgroundColor: const Color(0xFFBFD0FF),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Submit Review",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String name,
    required String date,
    required int rating,
    required String text,
    required int helpful,
    required String initial,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFE9EEF9),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFF1F3FAF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Color(0xFF98A2B3),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    size: 10,
                    color: index < rating
                        ? const Color(0xFFF4B400)
                        : const Color(0xFFD0D5DD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 8.5,
                color: Color(0xFF475467),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.thumb_up_alt_outlined,
                size: 10,
                color: Color(0xFF667085),
              ),
              const SizedBox(width: 4),
              Text(
                "Helpful ($helpful)",
                style: const TextStyle(
                  fontSize: 8,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
