import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mechfixes/Mechanic/mechanic_profile_data.dart';
import 'package:mechfixes/Mechanic/add_skills_services_screen.dart';
import 'package:mechfixes/Mechanic/mechanic_inbox_screen.dart';
import 'package:mechfixes/Mechanic/mechanic_profile_edit_screen.dart';
import 'package:mechfixes/chat/screens/chat_screen.dart';
import 'package:mechfixes/core/navigation/auth_navigation.dart';
import 'package:mechfixes/core/session/app_session.dart';

class MechanicDashboardScreen extends StatefulWidget {
  const MechanicDashboardScreen({
    super.key,
    this.profileData = const MechanicProfileData(email: "eliteauto@example.com"),
  });

  final MechanicProfileData profileData;

  @override
  State<MechanicDashboardScreen> createState() => _MechanicDashboardScreenState();
}

class _MechanicDashboardScreenState extends State<MechanicDashboardScreen> {
  late MechanicProfileData _profileData;
  bool _isLoadingProfile = false;

  MechanicProfileData get profileData => _profileData;

  String get _mechanicId =>
      FirebaseAuth.instance.currentUser?.uid ?? AppSession.demoMechanicId;

  @override
  void initState() {
    super.initState();
    _profileData = widget.profileData;
    if (_profileData.shopName.trim().isEmpty) {
      _loadProfileFromFirestore();
    }
  }

  Future<void> _loadProfileFromFirestore() async {
    setState(() => _isLoadingProfile = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc =
          await FirebaseFirestore.instance.collection('mechanics').doc(uid).get();

      if (!doc.exists || !mounted) return;

      final data = doc.data()!;
      final specialties = (data['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      setState(() {
        _profileData = MechanicProfileData(
          email: data['email'] as String? ?? _profileData.email,
          shopName: data['shopName'] as String? ?? '',
          phone: data['phone'] as String? ?? '',
          address: (data['location'] as String?) ??
              (data['address'] as String?) ??
              '',
          specialties: specialties,
          openingDays: data['openingDays'] as String? ?? '',
          openingHours: data['openingHours'] as String? ?? '',
        );
      });
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.push<MechanicProfileData>(
      context,
      MaterialPageRoute(
        builder: (_) => MechanicProfileEditScreen(
          initialEmail: profileData.email,
          initialShopName: profileData.shopName,
          initialPhone: profileData.phone,
          initialAddress: profileData.address,
          initialSpecialty: profileData.specialty,
          initialSpecialties: profileData.specialties,
          initialSpecialtyServices: profileData.specialtyServices,
          initialOpeningDays: profileData.openingDays,
          initialOpeningHours: profileData.openingHours,
          initialPhotoBytes: profileData.photoBytes,
          initialPhotoScale: profileData.photoScale,
          initialPhotoAlignmentX: profileData.photoAlignmentX,
          initialPhotoAlignmentY: profileData.photoAlignmentY,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _profileData = result;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Shop details updated successfully")),
    );
  }

  Future<void> _openAddSkillsServices() async {
    if (profileData.specialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add your specialty in shop profile first'),
        ),
      );
      return;
    }

    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddSkillsServicesScreen(
          mechanicId: _mechanicId,
          specializations: profileData.specialties,
          initialSelectedServices: profileData.selectedSkills,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _profileData = MechanicProfileData(
        email: profileData.email,
        shopName: profileData.shopName,
        phone: profileData.phone,
        address: profileData.address,
        specialties: profileData.specialties,
        specialtyServices: profileData.specialtyServices,
        selectedSkills: result,
        openingDays: profileData.openingDays,
        openingHours: profileData.openingHours,
        photoBytes: profileData.photoBytes,
        photoScale: profileData.photoScale,
        photoAlignmentX: profileData.photoAlignmentX,
        photoAlignmentY: profileData.photoAlignmentY,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.length} services saved')),
    );
  }

  Future<void> _openCustomerChat(String customerName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          receiverId: AppSession.demoCustomerId,
          receiverName: customerName,
        ),
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _reviewsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('reviews')
        .where('mechanicId', isEqualTo: uid)
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortedReviewDocs(
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

  Widget _buildReviewsBody({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String? loadError,
  }) {
    final int totalReviews = docs.length;

    double averageRating = 0.0;
    if (totalReviews > 0) {
      final ratingSum = docs.fold<double>(
        0.0,
        (total, doc) => total + _readRating(doc.data()['rating']),
      );
      averageRating = ratingSum / totalReviews;
    }

    final int thisMonthReviews = docs.where((doc) {
      final createdAt = doc.data()['createdAt'];
      return createdAt is Timestamp && _isThisMonth(createdAt);
    }).length;

    final int pendingReplies = docs.where((doc) {
      return _isPendingReply(doc.data());
    }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          if (loadError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4F4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD6D6)),
              ),
              child: Text(
                loadError,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB42318),
                ),
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: _DashboardStatCard(
                  title: "Total Reviews",
                  value: totalReviews.toString(),
                  icon: Icons.reviews_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardStatCard(
                  title: "Average Rating",
                  value: averageRating.toStringAsFixed(1),
                  icon: Icons.star_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DashboardStatCard(
                  title: "This Month",
                  value: thisMonthReviews.toString(),
                  icon: Icons.calendar_month_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardStatCard(
                  title: "Pending Replies",
                  value: pendingReplies.toString(),
                  icon: Icons.chat_bubble_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _openAddSkillsServices,
              icon: const Icon(Icons.build_circle_outlined, size: 18),
              label: const Text('Add Skills / Services'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1F3FAF),
                side: const BorderSide(color: Color(0xFF1F3FAF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD7DDE8)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  "Customer Reviews",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (docs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                loadError == null ? 'No reviews yet' : 'Reviews unavailable',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final userName = data['userName'] as String? ?? 'Customer';
                final reviewText = data['reviewText'] as String? ??
                    data['review'] as String? ??
                    '';
                final rating = _readRating(data['rating']).round();
                final date = _formatReviewDate(data['createdAt']);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReviewCard(
                    review: {
                      'name': userName,
                      'date': date,
                      'rating': rating,
                      'review': reviewText,
                    },
                    onReply: () => _openCustomerChat(userName),
                    onMarkAsRead: () => _markReviewAsRead(doc.id),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  double _readRating(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatReviewDate(dynamic createdAt) {
    if (createdAt is! Timestamp) return '—';

    final date = createdAt.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return '1 day ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 14) return '1 week ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  bool _isThisMonth(Timestamp? createdAt) {
    if (createdAt == null) return false;
    final date = createdAt.toDate();
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  bool _isPendingReply(Map<String, dynamic> data) {
    final isRead = data['isRead'] as bool? ?? false;
    final hasReplied = data['hasReplied'] as bool? ?? false;
    return !isRead || !hasReplied;
  }

  Future<void> _markReviewAsRead(String reviewId) async {
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .update({'isRead': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: _isLoadingProfile
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1F3FAF)),
              )
            : Column(
                children: [
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: const Color(0xFF1F3FAF),
                    child: Row(
                      children: [
                        const Icon(Icons.build_circle_outlined,
                            color: Colors.white, size: 26),
                        const SizedBox(width: 10),
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mechanic Dashboard",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Manage shop and customer reviews",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MechanicInboxScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: _openEditProfile,
                          icon: const Icon(Icons.settings_outlined,
                              color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () => logoutToLogin(context),
                          icon: const Icon(Icons.logout, color: Colors.white),
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _reviewsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF1F3FAF),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return _buildReviewsBody(
                            docs: <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                            loadError:
                                'Could not load reviews. Check Firestore rules for the reviews collection.',
                          );
                        }

                        final docs =
                            _sortedReviewDocs(snapshot.data?.docs ?? []);

                        return _buildReviewsBody(docs: docs);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD7DDE8)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1F3FAF), size: 22),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback onReply;
  final VoidCallback onMarkAsRead;

  const _ReviewCard({
    required this.review,
    required this.onReply,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final int rating = review["rating"] as int;
    final String name = review["name"] as String;
    final String initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD7DDE8)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE8EEFF),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFF1F3FAF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review["name"],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101828),
                      ),
                    ),
                    Text(
                      review["date"],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667085),
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
                    size: 16,
                    color:
                    index < rating ? Colors.amber : const Color(0xFFD0D5DD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review["review"],
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF475467),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: onReply,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD7DDE8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Reply"),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: onMarkAsRead,
                child: const Text("Mark as Read"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}