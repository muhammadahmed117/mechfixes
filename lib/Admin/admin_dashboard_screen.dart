import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mechfixes/data/models/mechanic_record.dart';
import 'package:mechfixes/data/models/user_record.dart';
import 'package:mechfixes/data/parsers/firestore_parsers.dart';
import 'package:mechfixes/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Portal
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const _scaffoldBg = Color(0xFFF3F5F9);
  static const _appBarBg = Color(0xFF212936);

  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        backgroundColor: _appBarBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Admin Portal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email…',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            onPressed: _searchController.clear,
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.12),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Mechanics'),
                  Tab(text: 'Users'),
                  Tab(text: 'Complaints'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingTab(searchQuery: _searchQuery),
          const _ApprovedMechanicsTab(),
          _UsersTab(searchQuery: _searchQuery),
          const _ComplaintsTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers & widgets
// ─────────────────────────────────────────────────────────────────────────────

bool _matchesQuery(String query, List<String> fields) {
  if (query.isEmpty) return true;
  for (final field in fields) {
    if (field.toLowerCase().contains(query)) return true;
  }
  return false;
}

String _str(dynamic value, [String fallback = '—']) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _mechanicSpecialization(MechanicRecord mechanic) {
  if (mechanic.specialties.isNotEmpty) {
    return mechanic.specialties.join(', ');
  }
  if (mechanic.selectedSkills.isNotEmpty) {
    return mechanic.selectedSkills.join(', ');
  }
  return '—';
}

Future<void> _launchEmail(String email) async {
  final uri = Uri(scheme: 'mailto', path: email);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

class _StyledCard extends StatelessWidget {
  const _StyledCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _TabLoader extends StatelessWidget {
  const _TabLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFFF4D4F)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.title, required this.rows});

  final String title;
  final List<({IconData icon, String label, String value})> rows;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212936),
                ),
              ),
              const SizedBox(height: 20),
              ...rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(row.icon, size: 20, color: const Color(0xFF64748B)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              row.value,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StarRatingRow extends StatelessWidget {
  const _StarRatingRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rating.round().clamp(0, 5);
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: 16,
          color: filled ? Colors.amber : Colors.grey.shade300,
        );
      }),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Pending Requests
// ─────────────────────────────────────────────────────────────────────────────

class _PendingTab extends StatefulWidget {
  const _PendingTab({required this.searchQuery});

  final String searchQuery;

  @override
  State<_PendingTab> createState() => _PendingTabState();
}

class _PendingTabState extends State<_PendingTab> {
  final Set<String> _processingIds = {};

  Future<void> _approve(BuildContext context, String mechanicId) async {
    if (_processingIds.contains(mechanicId)) return;

    setState(() => _processingIds.add(mechanicId));

    try {
      await FirebaseFirestore.instance
          .collection('mechanics')
          .doc(mechanicId)
          .update({
        'status': 'approved',
        'isVerified': true,
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mechanic Approved Successfully'),
          backgroundColor: Color(0xFF1FAB5D),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(mechanicId));
      }
    }
  }

  Future<void> _reject(BuildContext context, String mechanicId) async {
    if (_processingIds.contains(mechanicId)) return;

    setState(() => _processingIds.add(mechanicId));

    try {
      await FirebaseFirestore.instance
          .collection('mechanics')
          .doc(mechanicId)
          .update({
        'status': 'rejected',
        'isVerified': false,
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mechanic Rejected'),
          backgroundColor: Color(0xFFFF4D4F),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(mechanicId));
      }
    }
  }

  bool _isPending(MechanicRecord mechanic) =>
      !mechanic.isVerified && !mechanic.isRejected;

  void _showDetails(BuildContext context, MechanicRecord mechanic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        title: mechanic.displayName.isNotEmpty
            ? mechanic.displayName
            : 'Mechanic Details',
        rows: [
          (
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: mechanic.phone.isNotEmpty ? mechanic.phone : '—',
          ),
          (
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: mechanic.address.isNotEmpty ? mechanic.address : '—',
          ),
          (
            icon: Icons.build_outlined,
            label: 'Specialization',
            value: _mechanicSpecialization(mechanic),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('mechanics').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _TabLoader();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: 'Failed to load pending requests.\n${snapshot.error}',
          );
        }

        final mechanics = FirestoreParsers.parseDocs(
          snapshot.data?.docs ?? [],
          MechanicRecord.fromFirestore,
          logLabel: 'AdminPending',
        ).where((mechanic) {
          if (!_isPending(mechanic)) return false;
          return _matchesQuery(
            widget.searchQuery,
            [mechanic.fullName, mechanic.email, mechanic.shopName],
          );
        }).toList();

        if (mechanics.isEmpty) {
          return const _EmptyState(
            icon: Icons.pending_actions_outlined,
            message: 'No records found',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mechanics.length,
          itemBuilder: (context, index) {
            final mechanic = mechanics[index];
            final displayName = mechanic.displayName.isNotEmpty
                ? mechanic.displayName
                : 'Unknown';
            final email = mechanic.email.isNotEmpty ? mechanic.email : '—';
            final initial =
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

            final isProcessing = _processingIds.contains(mechanic.uid);

            return _StyledCard(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showDetails(context, mechanic),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFE2E8F0),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionButton(
                              label: 'Approve',
                              color: const Color(0xFF1FAB5D),
                              icon: Icons.check,
                              isLoading: isProcessing,
                              onPressed: () => _approve(context, mechanic.uid),
                            ),
                            const SizedBox(width: 8),
                            _ActionButton(
                              label: 'Reject',
                              color: const Color(0xFFFF4D4F),
                              icon: Icons.close,
                              isLoading: isProcessing,
                              onPressed: () => _reject(context, mechanic.uid),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Approved Mechanics
// ─────────────────────────────────────────────────────────────────────────────

enum _MechanicSort { highestRated, recent }

class _ApprovedMechanicsTab extends StatefulWidget {
  const _ApprovedMechanicsTab();

  @override
  State<_ApprovedMechanicsTab> createState() => _ApprovedMechanicsTabState();
}

class _ApprovedMechanicsTabState extends State<_ApprovedMechanicsTab> {
  _MechanicSort _sort = _MechanicSort.highestRated;

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sort Mechanics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Highest Rated'),
                trailing: _sort == _MechanicSort.highestRated
                    ? const Icon(Icons.check, color: Color(0xFF3B82F6))
                    : null,
                onTap: () {
                  setState(() => _sort = _MechanicSort.highestRated);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Recent'),
                trailing: _sort == _MechanicSort.recent
                    ? const Icon(Icons.check, color: Color(0xFF3B82F6))
                    : null,
                onTap: () {
                  setState(() => _sort = _MechanicSort.recent);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showDetails(BuildContext context, MechanicRecord mechanic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        title: mechanic.fullName.isNotEmpty ? mechanic.fullName : 'Mechanic Profile',
        rows: [
          (
            icon: Icons.store_outlined,
            label: 'Shop Name',
            value: mechanic.shopName.isNotEmpty ? mechanic.shopName : '—',
          ),
          (
            icon: Icons.location_on_outlined,
            label: 'Exact Location',
            value: mechanic.address.isNotEmpty ? mechanic.address : '—',
          ),
          (
            icon: Icons.phone_outlined,
            label: 'Contact Number',
            value: mechanic.phone.isNotEmpty ? mechanic.phone : '—',
          ),
          (
            icon: Icons.email_outlined,
            label: 'Gmail',
            value: mechanic.email.isNotEmpty ? mechanic.email : '—',
          ),
          (
            icon: Icons.star_outline,
            label: 'Rating',
            value: '${mechanic.rating.toStringAsFixed(1)} (${mechanic.reviewCount} reviews)',
          ),
        ],
      ),
    );
  }

  List<MechanicRecord> _sortedMechanics(List<MechanicRecord> mechanics) {
    final sorted = List<MechanicRecord>.from(mechanics);
    if (_sort == _MechanicSort.highestRated) {
      sorted.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      sorted.sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        if (aTime != null && bTime != null) {
          return bTime.compareTo(aTime);
        }
        return 0;
      });
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('mechanics').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _TabLoader();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: 'Failed to load mechanics.\n${snapshot.error}',
          );
        }

        final mechanics = _sortedMechanics(
          FirestoreParsers.parseDocs(
            snapshot.data?.docs ?? [],
            MechanicRecord.fromFirestore,
            logLabel: 'AdminMechanics',
          ).where((mechanic) => mechanic.isVerified).toList(),
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Text(
                    '${mechanics.length} mechanic${mechanics.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Filter & Sort',
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showFilterMenu,
                  ),
                ],
              ),
            ),
            Expanded(
              child: mechanics.isEmpty
                  ? const _EmptyState(
                      icon: Icons.engineering_outlined,
                      message: 'No records found',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: mechanics.length,
                      itemBuilder: (context, index) {
                        final mechanic = mechanics[index];
                        final displayName = mechanic.displayName.isNotEmpty
                            ? mechanic.displayName
                            : 'Unknown';
                        final email =
                            mechanic.email.isNotEmpty ? mechanic.email : '—';
                        final initial = displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?';

                        return _StyledCard(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showDetails(context, mechanic),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFDCFCE7),
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          email,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            _StarRatingRow(rating: mechanic.rating),
                                            const SizedBox(width: 6),
                                            Text(
                                              mechanic.rating.toStringAsFixed(1),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.verified,
                                    color: Color(0xFF16A34A),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Users
// ─────────────────────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _TabLoader();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: 'Failed to load users.\n${snapshot.error}',
          );
        }

        final users = FirestoreParsers.parseDocs(
          snapshot.data?.docs ?? [],
          UserRecord.fromFirestore,
          logLabel: 'AdminUsers',
        ).where((user) {
          return _matchesQuery(
            searchQuery,
            [user.fullName, user.email],
          );
        }).toList();

        if (users.isEmpty) {
          return const _EmptyState(
            icon: Icons.people_outline,
            message: 'No records found',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final fullName = user.displayName;
            final email = user.email.isNotEmpty ? user.email : '—';
            final joined = _formatDate(user.createdAt);

            return _StyledCard(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF1F5F9),
                  child: Icon(Icons.person_outline, color: Color(0xFF64748B)),
                ),
                title: Text(
                  fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(email, style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Joined $joined',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  tooltip: 'Send email',
                  icon: const Icon(Icons.email_outlined, color: Color(0xFF3B82F6)),
                  onPressed: email != '—' ? () => _launchEmail(email) : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 — Complaints
// ─────────────────────────────────────────────────────────────────────────────

class _ComplaintsTab extends StatelessWidget {
  const _ComplaintsTab();

  Future<void> _resolve(String docId) async {
    await FirebaseFirestore.instance
        .collection('complaints')
        .doc(docId)
        .update({'status': true});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _TabLoader();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: 'Failed to load complaints.\n${snapshot.error}',
          );
        }

        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final status = doc.data()['status'];
          return status != true;
        }).toList();

        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.report_gmailerrorred_outlined,
            message: 'No records found',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final reportedBy = _str(
              data['userEmail'] ?? data['reportedBy'],
            );
            final against = _str(
              data['mechanicName'] ?? data['against'],
            );
            final issue = _str(data['issue'] ?? data['complaint'] ?? data['text']);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 5, color: const Color(0xFFFF6B35)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFFF6B35),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Complaint',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF212936),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _ComplaintField(label: 'Reported By', value: reportedBy),
                              const SizedBox(height: 8),
                              _ComplaintField(label: 'Against', value: against),
                              const SizedBox(height: 8),
                              _ComplaintField(label: 'Issue', value: issue),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: reportedBy != '—'
                                        ? () => _launchEmail(reportedBy)
                                        : null,
                                    icon: const Icon(Icons.mail_outline, size: 18),
                                    label: const Text('Contact User'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF3B82F6),
                                      side: const BorderSide(color: Color(0xFF3B82F6)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _ActionButton(
                                    label: 'Resolve',
                                    color: const Color(0xFF1FAB5D),
                                    icon: Icons.check_circle_outline,
                                    onPressed: () => _resolve(doc.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ComplaintField extends StatelessWidget {
  const _ComplaintField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
        ),
      ],
    );
  }
}
