import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mechfixes/Admin/widgets/admin_common_widgets.dart';
import 'package:mechfixes/Admin/widgets/admin_dialogs.dart';
import 'package:mechfixes/core/admin/admin_validators.dart';
import 'package:mechfixes/core/localization/app_text.dart';
import 'package:mechfixes/core/localization/language_toggle_button.dart';
import 'package:mechfixes/data/models/complaint_record.dart';
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
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _checkingAdmin = true;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
    _verifyAdminSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _verifyAdminSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      _redirectToLogin();
      return;
    }

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (!adminDoc.exists) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _redirectToLogin();
        return;
      }

      setState(() {
        _isAuthorized = true;
        _checkingAdmin = false;
      });
    } catch (_) {
      if (!mounted) return;
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    _redirectToLogin();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAdmin || !_isAuthorized) {
      return const Scaffold(
        backgroundColor: AdminTheme.scaffold,
        body: Center(
          child: CircularProgressIndicator(color: AdminTheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AdminTheme.scaffold,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: AdminTheme.primary,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AdminTheme.headerGradient),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppText.of(
                context,
                english: 'Admin Portal',
                romanUrdu: 'Admin Portal',
              ),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              AppText.of(
                context,
                english: 'Manage mechanics, users & reports',
                romanUrdu: 'Mechanics, users aur reports manage karein',
              ),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          const LanguageToggleButton(compact: true),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.white),
            tooltip: AppText.of(
              context,
              english: 'Logout',
              romanUrdu: 'Logout',
            ),
            onPressed: _logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AdminTheme.ink, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: AppText.of(
                      context,
                      english: 'Search by name or email…',
                      romanUrdu: 'Naam ya email se talash karein…',
                    ),
                    hintStyle: TextStyle(
                      color: AdminTheme.muted.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AdminTheme.primary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AdminTheme.muted,
                            ),
                            onPressed: _searchController.clear,
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.62),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(
                    height: 46,
                    child: _AdminTabLabel(
                      icon: Icons.hourglass_top_rounded,
                      label: AppText.of(
                        context,
                        english: 'Pending',
                        romanUrdu: 'Baaki',
                      ),
                    ),
                  ),
                  Tab(
                    height: 46,
                    child: _AdminTabLabel(
                      icon: Icons.build_circle_outlined,
                      label: AppText.of(
                        context,
                        english: 'Mechanics',
                        romanUrdu: 'Mechanics',
                      ),
                    ),
                  ),
                  Tab(
                    height: 46,
                    child: _AdminTabLabel(
                      icon: Icons.people_alt_outlined,
                      label: AppText.of(
                        context,
                        english: 'Users',
                        romanUrdu: 'Users',
                      ),
                    ),
                  ),
                  Tab(
                    height: 46,
                    child: _AdminTabLabel(
                      icon: Icons.report_outlined,
                      label: AppText.of(
                        context,
                        english: 'Complaints',
                        romanUrdu: 'Shikayaat',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _AdminPortalBody(
        tabController: _tabController,
        searchQuery: _searchQuery,
      ),
    );
  }
}

class _AdminTabLabel extends StatelessWidget {
  const _AdminTabLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: selected ? AdminTheme.headerGradient : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFFD0D5DD),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AdminTheme.ink,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

bool _matchesQuery(String query, List<String> fields) {
  if (query.isEmpty) return true;
  for (final field in fields) {
    if (field.toLowerCase().contains(query)) return true;
  }
  return false;
}

String _displayOrDash(String value) {
  final text = value.trim();
  return text.isEmpty ? '—' : text;
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

void _showSnack(
  BuildContext context,
  String message, {
  Color background = const Color(0xFF1FAB5D),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: background),
  );
}

Future<void> _launchEmail(BuildContext context, String email) async {
  if (!AdminValidators.isValidEmail(email)) {
    _showSnack(
      context,
      AppText.of(
        context,
        english: 'Invalid email address',
        romanUrdu: 'Email ghalat hai',
      ),
      background: Colors.redAccent,
    );
    return;
  }

  final uri = Uri(scheme: 'mailto', path: email.trim());
  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      _showSnack(
        context,
        AppText.of(
          context,
          english: 'Could not open email app',
          romanUrdu: 'Email app nahi khuli',
        ),
        background: Colors.redAccent,
      );
    }
  } catch (_) {
    if (context.mounted) {
      _showSnack(
        context,
        AppText.of(
          context,
          english: 'Could not open email app',
          romanUrdu: 'Email app nahi khuli',
        ),
        background: Colors.redAccent,
      );
    }
  }
}

Future<void> _launchPhone(BuildContext context, String phone) async {
  final normalized = AdminValidators.normalizePhone(phone);
  if (normalized == null) {
    _showSnack(
      context,
      AppText.of(
        context,
        english: 'Invalid phone number',
        romanUrdu: 'Phone number ghalat hai',
      ),
      background: Colors.redAccent,
    );
    return;
  }

  final uri = Uri(scheme: 'tel', path: normalized);
  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      _showSnack(
        context,
        AppText.of(
          context,
          english: 'Could not open phone dialer',
          romanUrdu: 'Call app nahi khuli',
        ),
        background: Colors.redAccent,
      );
    }
  } catch (_) {
    if (context.mounted) {
      _showSnack(
        context,
        AppText.of(
          context,
          english: 'Could not open phone dialer',
          romanUrdu: 'Call app nahi khuli',
        ),
        background: Colors.redAccent,
      );
    }
  }
}

class _StyledCard extends StatelessWidget {
  const _StyledCard({required this.child, this.accentColor});

  final Widget child;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AdminTheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AdminTheme.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabLoader extends StatelessWidget {
  const _TabLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AdminTheme.primary),
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AdminTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AdminTheme.primary),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AdminTheme.muted,
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AdminTheme.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 34,
                color: AdminTheme.danger,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AdminTheme.muted),
            ),
          ],
        ),
      ),
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
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: filled ? const Color(0xFFFDB022) : const Color(0xFFD0D5DD),
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
    this.outlined = false,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        height: 34,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.45)),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            minimumSize: const Size(0, 34),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: isLoading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, size: 15),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      );
    }

    return SizedBox(
      height: 34,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: color.withValues(alpha: 0.35),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              )
            : Icon(icon, size: 15),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}

void _showMechanicDetails(BuildContext context, MechanicRecord mechanic) {
  final coords = mechanic.hasCoordinates
      ? '${mechanic.latitude!.toStringAsFixed(5)}, '
          '${mechanic.longitude!.toStringAsFixed(5)}'
      : '—';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AdminDetailSheet(
      title: mechanic.displayName.isNotEmpty
          ? mechanic.displayName
          : 'Mechanic Details',
      rows: [
        AdminDetailRow(
          icon: Icons.person_outline,
          label: AppText.of(context, english: 'Full name', romanUrdu: 'Poora naam'),
          value: _displayOrDash(mechanic.fullName),
        ),
        AdminDetailRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: _displayOrDash(mechanic.email),
        ),
        AdminDetailRow(
          icon: Icons.storefront_outlined,
          label: AppText.of(context, english: 'Shop', romanUrdu: 'Shop'),
          value: _displayOrDash(mechanic.shopName),
        ),
        AdminDetailRow(
          icon: Icons.phone_outlined,
          label: AppText.of(context, english: 'Phone', romanUrdu: 'Phone'),
          value: _displayOrDash(mechanic.phone),
        ),
        AdminDetailRow(
          icon: Icons.location_on_outlined,
          label: AppText.of(context, english: 'Address', romanUrdu: 'Address'),
          value: _displayOrDash(mechanic.address),
        ),
        AdminDetailRow(
          icon: Icons.build_outlined,
          label: AppText.of(
            context,
            english: 'Specialties',
            romanUrdu: 'Specialties',
          ),
          value: _mechanicSpecialization(mechanic),
        ),
        AdminDetailRow(
          icon: Icons.handyman_outlined,
          label: AppText.of(context, english: 'Skills', romanUrdu: 'Skills'),
          value: mechanic.selectedSkills.isEmpty
              ? '—'
              : mechanic.selectedSkills.join(', '),
        ),
        AdminDetailRow(
          icon: Icons.my_location_outlined,
          label: AppText.of(
            context,
            english: 'Coordinates',
            romanUrdu: 'Coordinates',
          ),
          value: coords,
        ),
        AdminDetailRow(
          icon: Icons.info_outline,
          label: 'Status',
          value: mechanic.status,
        ),
        if (mechanic.adminNote.isNotEmpty)
          AdminDetailRow(
            icon: Icons.notes_outlined,
            label: AppText.of(
              context,
              english: 'Admin note',
              romanUrdu: 'Admin note',
            ),
            value: mechanic.adminNote,
          ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Firestore body (one listener per collection)
// ─────────────────────────────────────────────────────────────────────────────

class _AdminPortalBody extends StatelessWidget {
  const _AdminPortalBody({
    required this.tabController,
    required this.searchQuery,
  });

  final TabController tabController;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('mechanics').snapshots(),
      builder: (context, mechSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, userSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .snapshots(),
              builder: (context, complaintSnap) {
                final waiting = mechSnap.connectionState ==
                        ConnectionState.waiting ||
                    userSnap.connectionState == ConnectionState.waiting ||
                    complaintSnap.connectionState == ConnectionState.waiting;

                if (waiting &&
                    mechSnap.data == null &&
                    userSnap.data == null &&
                    complaintSnap.data == null) {
                  return const _TabLoader();
                }

                if (mechSnap.hasError ||
                    userSnap.hasError ||
                    complaintSnap.hasError) {
                  return _ErrorState(
                    message: AppText.of(
                      context,
                      english:
                          'Failed to load admin data.\n${mechSnap.error ?? userSnap.error ?? complaintSnap.error}',
                      romanUrdu:
                          'Admin data load nahi hua.\n${mechSnap.error ?? userSnap.error ?? complaintSnap.error}',
                    ),
                  );
                }

                final mechanics = FirestoreParsers.parseDocs(
                  mechSnap.data?.docs ?? const [],
                  MechanicRecord.fromFirestore,
                  logLabel: 'AdminMechanics',
                );
                final users = FirestoreParsers.parseDocs(
                  userSnap.data?.docs ?? const [],
                  UserRecord.fromFirestore,
                  logLabel: 'AdminUsers',
                );
                final complaints = FirestoreParsers.parseDocs(
                  complaintSnap.data?.docs ?? const [],
                  ComplaintRecord.fromFirestore,
                  logLabel: 'AdminComplaints',
                );

                return Column(
                  children: [
                    _AdminStatsHeader(
                      pendingCount:
                          mechanics.where((m) => m.isPendingApproval).length,
                      verifiedCount:
                          mechanics.where((m) => m.isApproved).length,
                      userCount: users.length,
                      openComplaintCount:
                          complaints.where((c) => c.isOpen).length,
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          _PendingTab(
                            mechanics: mechanics,
                            searchQuery: searchQuery,
                          ),
                          _MechanicsTab(
                            mechanics: mechanics,
                            searchQuery: searchQuery,
                          ),
                          _UsersTab(
                            users: users,
                            searchQuery: searchQuery,
                          ),
                          _ComplaintsTab(
                            complaints: complaints,
                            searchQuery: searchQuery,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats header
// ─────────────────────────────────────────────────────────────────────────────

class _AdminStatsHeader extends StatelessWidget {
  const _AdminStatsHeader({
    required this.pendingCount,
    required this.verifiedCount,
    required this.userCount,
    required this.openComplaintCount,
  });

  final int pendingCount;
  final int verifiedCount;
  final int userCount;
  final int openComplaintCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 2),
      child: SizedBox(
        height: 60,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            AdminStatsCard(
              label: AppText.of(
                context,
                english: 'Pending',
                romanUrdu: 'Baaki',
              ),
              value: '$pendingCount',
              icon: Icons.hourglass_top_rounded,
              color: AdminTheme.warning,
            ),
            const SizedBox(width: 8),
            AdminStatsCard(
              label: AppText.of(
                context,
                english: 'Verified',
                romanUrdu: 'Verified',
              ),
              value: '$verifiedCount',
              icon: Icons.verified_rounded,
              color: AdminTheme.success,
            ),
            const SizedBox(width: 8),
            AdminStatsCard(
              label: AppText.of(
                context,
                english: 'Users',
                romanUrdu: 'Users',
              ),
              value: '$userCount',
              icon: Icons.people_alt_rounded,
              color: AdminTheme.primary,
            ),
            const SizedBox(width: 8),
            AdminStatsCard(
              label: AppText.of(
                context,
                english: 'Open complaints',
                romanUrdu: 'Open shikayaat',
              ),
              value: '$openComplaintCount',
              icon: Icons.report_rounded,
              color: AdminTheme.danger,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Pending
// ─────────────────────────────────────────────────────────────────────────────

class _PendingTab extends StatefulWidget {
  const _PendingTab({
    required this.mechanics,
    required this.searchQuery,
  });

  final List<MechanicRecord> mechanics;
  final String searchQuery;

  @override
  State<_PendingTab> createState() => _PendingTabState();
}

class _PendingTabState extends State<_PendingTab> {
  final Set<String> _processingIds = {};

  Future<void> _approve(BuildContext context, MechanicRecord mechanic) async {
    if (_processingIds.contains(mechanic.uid)) return;

    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: AppText.of(context, english: 'Approve mechanic?', romanUrdu: 'Approve karein?'),
      message: AppText.of(
        context,
        english:
            'Approve ${mechanic.displayName}? They will appear as verified.',
        romanUrdu:
            '${mechanic.displayName} ko approve karein? Woh verified dikhengay.',
      ),
      confirmLabel: AppText.of(context, english: 'Approve', romanUrdu: 'Approve'),
      confirmColor: const Color(0xFF1FAB5D),
      icon: Icons.check_circle_outline,
    );
    if (!confirmed || !mounted) return;

    setState(() => _processingIds.add(mechanic.uid));
    try {
      await FirebaseFirestore.instance
          .collection('mechanics')
          .doc(mechanic.uid)
          .update({
        'status': 'approved',
        'isVerified': true,
        'adminNote': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      _showSnack(
        context,
        AppText.of(
          context,
          english: 'Mechanic approved',
          romanUrdu: 'Mechanic approve ho gaya',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, e.toString(), background: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _processingIds.remove(mechanic.uid));
    }
  }

  Future<void> _reject(BuildContext context, MechanicRecord mechanic) async {
    if (_processingIds.contains(mechanic.uid)) return;

    final reason = await showAdminReasonDialog(
      context: context,
      title: AppText.of(
        context,
        english: 'Reject mechanic',
        romanUrdu: 'Mechanic reject karein',
      ),
      hint: AppText.of(
        context,
        english: 'Reason for rejection…',
        romanUrdu: 'Reject ki wajah…',
      ),
      confirmLabel: AppText.of(context, english: 'Reject', romanUrdu: 'Reject'),
    );
    if (reason == null || !mounted) return;

    setState(() => _processingIds.add(mechanic.uid));
    try {
      await FirebaseFirestore.instance
          .collection('mechanics')
          .doc(mechanic.uid)
          .update({
        'status': 'rejected',
        'isVerified': false,
        'adminNote': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      _showSnack(
        context,
        AppText.of(
          context,
          english: 'Mechanic rejected',
          romanUrdu: 'Mechanic reject ho gaya',
        ),
        background: const Color(0xFFFF4D4F),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, e.toString(), background: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _processingIds.remove(mechanic.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mechanics = widget.mechanics
        .where((m) => m.isPendingApproval)
        .where((m) {
          return _matchesQuery(widget.searchQuery, [
            m.fullName,
            m.shopName,
            m.email,
            m.phone,
            ...m.specialties,
          ]);
        })
        .toList();

    if (mechanics.isEmpty) {
      return _EmptyState(
        icon: Icons.inbox_outlined,
        message: AppText.of(
          context,
          english: widget.searchQuery.isEmpty
              ? 'No pending mechanic requests'
              : 'No matching pending requests',
          romanUrdu: widget.searchQuery.isEmpty
              ? 'Koi pending request nahi'
              : 'Koi match nahi mila',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: mechanics.length,
      itemBuilder: (context, index) {
        final mechanic = mechanics[index];
        final processing = _processingIds.contains(mechanic.uid);
        final specialty = _mechanicSpecialization(mechanic);

        return _StyledCard(
          accentColor: AdminTheme.warning,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AdminTheme.warning.withValues(alpha: 0.15),
                      child: Text(
                        (mechanic.displayName.isNotEmpty
                                ? mechanic.displayName[0]
                                : '?')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AdminTheme.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  mechanic.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AdminTheme.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const AdminStatusChip(
                                label: 'Pending',
                                color: AdminTheme.warning,
                                icon: Icons.hourglass_top,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _displayOrDash(mechanic.email),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AdminTheme.muted,
                            ),
                          ),
                          if (mechanic.phone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              mechanic.phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AdminTheme.muted,
                              ),
                            ),
                          ],
                          if (specialty != '—') ...[
                            const SizedBox(height: 4),
                            Text(
                              specialty,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _ActionButton(
                      label: AppText.of(
                        context,
                        english: 'Details',
                        romanUrdu: 'Details',
                      ),
                      color: AdminTheme.primary,
                      icon: Icons.visibility_outlined,
                      outlined: true,
                      onPressed: () =>
                          _showMechanicDetails(context, mechanic),
                    ),
                    _ActionButton(
                      label: AppText.of(
                        context,
                        english: 'Approve',
                        romanUrdu: 'Approve',
                      ),
                      color: AdminTheme.success,
                      icon: Icons.check,
                      isLoading: processing,
                      onPressed: () => _approve(context, mechanic),
                    ),
                    _ActionButton(
                      label: AppText.of(
                        context,
                        english: 'Reject',
                        romanUrdu: 'Reject',
                      ),
                      color: AdminTheme.danger,
                      icon: Icons.close,
                      isLoading: processing,
                      onPressed: () => _reject(context, mechanic),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Mechanics
// ─────────────────────────────────────────────────────────────────────────────

class _MechanicsTab extends StatefulWidget {
  const _MechanicsTab({
    required this.mechanics,
    required this.searchQuery,
  });

  final List<MechanicRecord> mechanics;
  final String searchQuery;

  @override
  State<_MechanicsTab> createState() => _MechanicsTabState();
}

class _MechanicsTabState extends State<_MechanicsTab> {
  final Set<String> _processingIds = {};
  String _filter = 'All';
  String _sort = 'Rating';

  Future<void> _unverify(BuildContext context, MechanicRecord mechanic) async {
    if (_processingIds.contains(mechanic.uid)) return;

    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: AppText.of(
        context,
        english: 'Move to pending?',
        romanUrdu: 'Pending par bhejein?',
      ),
      message: AppText.of(
        context,
        english:
            'Unverify ${mechanic.displayName}? They will return to pending approval.',
        romanUrdu:
            '${mechanic.displayName} ko unverify karein? Woh pending mein chale jayein ge.',
      ),
      confirmLabel:
          AppText.of(context, english: 'Unverify', romanUrdu: 'Unverify'),
      confirmColor: const Color(0xFFF59E0B),
      icon: Icons.undo,
    );
    if (!confirmed || !mounted) return;

    setState(() => _processingIds.add(mechanic.uid));
    try {
      await FirebaseFirestore.instance
          .collection('mechanics')
          .doc(mechanic.uid)
          .update({
        'status': 'pending',
        'isVerified': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      _showSnack(
        context,
        AppText.of(
          context,
          english: 'Mechanic moved to pending',
          romanUrdu: 'Mechanic pending mein chala gaya',
        ),
        background: const Color(0xFFF59E0B),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, e.toString(), background: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _processingIds.remove(mechanic.uid));
    }
  }

  Future<void> _reject(BuildContext context, MechanicRecord mechanic) async {
    if (_processingIds.contains(mechanic.uid)) return;

    final reason = await showAdminReasonDialog(
      context: context,
      title: AppText.of(
        context,
        english: 'Reject mechanic',
        romanUrdu: 'Mechanic reject karein',
      ),
      hint: AppText.of(
        context,
        english: 'Reason for rejection…',
        romanUrdu: 'Reject ki wajah…',
      ),
      confirmLabel: AppText.of(context, english: 'Reject', romanUrdu: 'Reject'),
    );
    if (reason == null || !mounted) return;

    setState(() => _processingIds.add(mechanic.uid));
    try {
      await FirebaseFirestore.instance
          .collection('mechanics')
          .doc(mechanic.uid)
          .update({
        'status': 'rejected',
        'isVerified': false,
        'adminNote': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      _showSnack(
        context,
        AppText.of(
          context,
          english: 'Mechanic rejected',
          romanUrdu: 'Mechanic reject ho gaya',
        ),
        background: const Color(0xFFFF4D4F),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, e.toString(), background: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _processingIds.remove(mechanic.uid));
    }
  }

  Future<void> _reopen(BuildContext context, MechanicRecord mechanic) async {
    if (_processingIds.contains(mechanic.uid)) return;

    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: AppText.of(
        context,
        english: 'Re-open application?',
        romanUrdu: 'Dobara open karein?',
      ),
      message: AppText.of(
        context,
        english:
            'Move ${mechanic.displayName} back to pending for re-review?',
        romanUrdu:
            '${mechanic.displayName} ko pending mein wapas bhejein?',
      ),
      confirmLabel: AppText.of(context, english: 'Re-open', romanUrdu: 'Re-open'),
      confirmColor: const Color(0xFF3B82F6),
      icon: Icons.refresh,
    );
    if (!confirmed || !mounted) return;

    setState(() => _processingIds.add(mechanic.uid));
    try {
      await FirebaseFirestore.instance
          .collection('mechanics')
          .doc(mechanic.uid)
          .update({
        'status': 'pending',
        'isVerified': false,
        'adminNote': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      _showSnack(
        context,
        AppText.of(
          context,
          english: 'Application re-opened',
          romanUrdu: 'Application dobara open ho gai',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, e.toString(), background: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _processingIds.remove(mechanic.uid));
    }
  }

  List<MechanicRecord> _applyFilter(List<MechanicRecord> all) {
    switch (_filter) {
      case 'Verified':
        return all.where((m) => m.isApproved).toList();
      case 'Rejected':
        return all.where((m) => m.isRejected).toList();
      default:
        return all.where((m) => m.isApproved || m.isRejected).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminFilterChipBar(
          options: const ['All', 'Verified', 'Rejected'],
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
          child: Row(
            children: [
              const Text(
                'Sort:',
                style: TextStyle(
                  fontSize: 12,
                  color: AdminTheme.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: AppText.of(context, english: 'Rating', romanUrdu: 'Rating'),
                selected: _sort == 'Rating',
                onTap: () => setState(() => _sort = 'Rating'),
              ),
              const SizedBox(width: 6),
              _SortChip(
                label: AppText.of(context, english: 'Recent', romanUrdu: 'Recent'),
                selected: _sort == 'Recent',
                onTap: () => setState(() => _sort = 'Recent'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              var mechanics = _applyFilter(widget.mechanics).where((m) {
                return _matchesQuery(widget.searchQuery, [
                  m.fullName,
                  m.shopName,
                  m.email,
                  m.phone,
                  m.address,
                  ...m.specialties,
                ]);
              }).toList();

              if (_sort == 'Rating') {
                mechanics.sort((a, b) => b.rating.compareTo(a.rating));
              } else {
                mechanics.sort((a, b) {
                  final aDate =
                      a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bDate =
                      b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bDate.compareTo(aDate);
                });
              }

              if (mechanics.isEmpty) {
                return _EmptyState(
                  icon: Icons.build_outlined,
                  message: AppText.of(
                    context,
                    english: 'No mechanics found',
                    romanUrdu: 'Koi mechanic nahi mila',
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: mechanics.length,
                itemBuilder: (context, index) {
                  final mechanic = mechanics[index];
                  final processing = _processingIds.contains(mechanic.uid);
                  final rejected = mechanic.isRejected;

                  return _StyledCard(
                    accentColor:
                        rejected ? AdminTheme.danger : AdminTheme.success,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: (rejected
                                        ? AdminTheme.danger
                                        : AdminTheme.success)
                                    .withValues(alpha: 0.15),
                                child: Icon(
                                  rejected ? Icons.block : Icons.verified,
                                  color: rejected
                                      ? AdminTheme.danger
                                      : AdminTheme.success,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            mechanic.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AdminTheme.ink,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        AdminStatusChip(
                                          label: rejected
                                              ? 'Rejected'
                                              : 'Verified',
                                          color: rejected
                                              ? AdminTheme.danger
                                              : AdminTheme.success,
                                          icon: rejected
                                              ? Icons.cancel_outlined
                                              : Icons.verified_outlined,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _displayOrDash(mechanic.email),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AdminTheme.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _mechanicSpecialization(mechanic),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    if (mechanic.address.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        mechanic.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AdminTheme.muted,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _StarRatingRow(rating: mechanic.rating),
                                        const SizedBox(width: 6),
                                        Text(
                                          mechanic.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AdminTheme.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _ActionButton(
                                label: AppText.of(
                                  context,
                                  english: 'Details',
                                  romanUrdu: 'Details',
                                ),
                                color: AdminTheme.primary,
                                icon: Icons.visibility_outlined,
                                outlined: true,
                                onPressed: () =>
                                    _showMechanicDetails(context, mechanic),
                              ),
                              if (AdminValidators.isValidEmail(mechanic.email))
                                _ActionButton(
                                  label: 'Email',
                                  color: AdminTheme.info,
                                  icon: Icons.email_outlined,
                                  onPressed: () =>
                                      _launchEmail(context, mechanic.email),
                                ),
                              if (AdminValidators.isValidPhone(mechanic.phone))
                                _ActionButton(
                                  label: AppText.of(
                                    context,
                                    english: 'Call',
                                    romanUrdu: 'Call',
                                  ),
                                  color: const Color(0xFF0EA5E9),
                                  icon: Icons.phone_outlined,
                                  onPressed: () =>
                                      _launchPhone(context, mechanic.phone),
                                ),
                              if (!rejected)
                                _ActionButton(
                                  label: AppText.of(
                                    context,
                                    english: 'Unverify',
                                    romanUrdu: 'Unverify',
                                  ),
                                  color: AdminTheme.warning,
                                  icon: Icons.undo,
                                  isLoading: processing,
                                  onPressed: () =>
                                      _unverify(context, mechanic),
                                ),
                              if (!rejected)
                                _ActionButton(
                                  label: AppText.of(
                                    context,
                                    english: 'Reject',
                                    romanUrdu: 'Reject',
                                  ),
                                  color: AdminTheme.danger,
                                  icon: Icons.close,
                                  isLoading: processing,
                                  onPressed: () => _reject(context, mechanic),
                                ),
                              if (rejected)
                                _ActionButton(
                                  label: AppText.of(
                                    context,
                                    english: 'Re-open',
                                    romanUrdu: 'Re-open',
                                  ),
                                  color: AdminTheme.primary,
                                  icon: Icons.refresh,
                                  isLoading: processing,
                                  onPressed: () => _reopen(context, mechanic),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Users
// ─────────────────────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab({
    required this.users,
    required this.searchQuery,
  });

  final List<UserRecord> users;
  final String searchQuery;

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final Set<String> _processingIds = {};
  String _filter = 'All';

  void _showUserDetails(BuildContext context, UserRecord user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminDetailSheet(
        title: user.displayName,
        rows: [
          AdminDetailRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _displayOrDash(user.email),
          ),
          AdminDetailRow(
            icon: Icons.phone_outlined,
            label: AppText.of(context, english: 'Phone', romanUrdu: 'Phone'),
            value: _displayOrDash(user.phone),
          ),
          AdminDetailRow(
            icon: Icons.badge_outlined,
            label: AppText.of(context, english: 'Role', romanUrdu: 'Role'),
            value: _displayOrDash(user.role),
          ),
          AdminDetailRow(
            icon: Icons.calendar_today_outlined,
            label: AppText.of(context, english: 'Joined', romanUrdu: 'Joined'),
            value: _formatDate(user.createdAt),
          ),
          AdminDetailRow(
            icon: Icons.info_outline,
            label: 'Status',
            value: user.isBlocked ? 'Blocked' : 'Active',
          ),
          if (user.adminNote.isNotEmpty)
            AdminDetailRow(
              icon: Icons.notes_outlined,
              label: AppText.of(
                context,
                english: 'Admin note',
                romanUrdu: 'Admin note',
              ),
              value: user.adminNote,
            ),
        ],
      ),
    );
  }

  Future<void> _block(BuildContext context, UserRecord user) async {
    if (_processingIds.contains(user.uid)) return;

    final reason = await showAdminReasonDialog(
      context: context,
      title: AppText.of(context, english: 'Block user', romanUrdu: 'User block karein'),
      hint: AppText.of(
        context,
        english: 'Reason for blocking…',
        romanUrdu: 'Block ki wajah…',
      ),
      confirmLabel: AppText.of(context, english: 'Block', romanUrdu: 'Block'),
    );
    if (reason == null || !mounted) return;

    setState(() => _processingIds.add(user.uid));
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'status': 'blocked',
        'isBlocked': true,
        'adminNote': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      _showSnack(
        context,
        AppText.of(
          context,
          english: 'User blocked',
          romanUrdu: 'User block ho gaya',
        ),
        background: const Color(0xFFFF4D4F),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, e.toString(), background: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _processingIds.remove(user.uid));
    }
  }

  Future<void> _unblock(BuildContext context, UserRecord user) async {
    if (_processingIds.contains(user.uid)) return;

    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: AppText.of(
        context,
        english: 'Unblock user?',
        romanUrdu: 'Unblock karein?',
      ),
      message: AppText.of(
        context,
        english: 'Restore access for ${user.displayName}?',
        romanUrdu: '${user.displayName} ka access wapas dein?',
      ),
      confirmLabel:
          AppText.of(context, english: 'Unblock', romanUrdu: 'Unblock'),
      confirmColor: const Color(0xFF1FAB5D),
      icon: Icons.lock_open,
    );
    if (!confirmed || !mounted) return;

    setState(() => _processingIds.add(user.uid));
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'status': 'active',
        'isBlocked': false,
        'adminNote': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      _showSnack(
        context,
        AppText.of(
          context,
          english: 'User unblocked',
          romanUrdu: 'User unblock ho gaya',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, e.toString(), background: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _processingIds.remove(user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminFilterChipBar(
          options: const ['All', 'Active', 'Blocked'],
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              var users = List<UserRecord>.from(widget.users);

              if (_filter == 'Active') {
                users = users.where((u) => u.isActive).toList();
              } else if (_filter == 'Blocked') {
                users = users.where((u) => u.isBlocked).toList();
              }

              users = users.where((u) {
                return _matchesQuery(widget.searchQuery, [
                  u.fullName,
                  u.email,
                  u.phone,
                  u.role,
                ]);
              }).toList();

              if (users.isEmpty) {
                return _EmptyState(
                  icon: Icons.people_outline,
                  message: AppText.of(
                    context,
                    english: 'No users found',
                    romanUrdu: 'Koi user nahi mila',
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final processing = _processingIds.contains(user.uid);

                  return _StyledCard(
                    accentColor:
                        user.isBlocked ? AdminTheme.danger : AdminTheme.primary,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: (user.isBlocked
                                        ? AdminTheme.danger
                                        : AdminTheme.primary)
                                    .withValues(alpha: 0.15),
                                child: Text(
                                  (user.displayName.isNotEmpty
                                          ? user.displayName[0]
                                          : '?')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: user.isBlocked
                                        ? AdminTheme.danger
                                        : AdminTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            user.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AdminTheme.ink,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        AdminStatusChip(
                                          label: user.isBlocked
                                              ? 'Blocked'
                                              : 'Active',
                                          color: user.isBlocked
                                              ? AdminTheme.danger
                                              : AdminTheme.success,
                                          icon: user.isBlocked
                                              ? Icons.block
                                              : Icons.check_circle_outline,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _displayOrDash(user.email),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AdminTheme.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${user.role} · ${_formatDate(user.createdAt)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AdminTheme.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _ActionButton(
                                label: AppText.of(
                                  context,
                                  english: 'Details',
                                  romanUrdu: 'Details',
                                ),
                                color: AdminTheme.primary,
                                icon: Icons.visibility_outlined,
                                outlined: true,
                                onPressed: () =>
                                    _showUserDetails(context, user),
                              ),
                              if (AdminValidators.isValidEmail(user.email))
                                _ActionButton(
                                  label: 'Email',
                                  color: AdminTheme.info,
                                  icon: Icons.email_outlined,
                                  onPressed: () =>
                                      _launchEmail(context, user.email),
                                ),
                              if (!user.isBlocked)
                                _ActionButton(
                                  label: AppText.of(
                                    context,
                                    english: 'Block',
                                    romanUrdu: 'Block',
                                  ),
                                  color: AdminTheme.danger,
                                  icon: Icons.block,
                                  isLoading: processing,
                                  onPressed: () => _block(context, user),
                                )
                              else
                                _ActionButton(
                                  label: AppText.of(
                                    context,
                                    english: 'Unblock',
                                    romanUrdu: 'Unblock',
                                  ),
                                  color: AdminTheme.success,
                                  icon: Icons.lock_open,
                                  isLoading: processing,
                                  onPressed: () => _unblock(context, user),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 — Complaints
// ─────────────────────────────────────────────────────────────────────────────

class _ComplaintsTab extends StatefulWidget {
  const _ComplaintsTab({
    required this.complaints,
    required this.searchQuery,
  });

  final List<ComplaintRecord> complaints;
  final String searchQuery;

  @override
  State<_ComplaintsTab> createState() => _ComplaintsTabState();
}

class _ComplaintsTabState extends State<_ComplaintsTab> {
  final Set<String> _processingIds = {};
  String _filter = 'Open';

  Future<void> _resolve(BuildContext context, ComplaintRecord complaint) async {
    if (_processingIds.contains(complaint.id)) return;

    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: AppText.of(
        context,
        english: 'Resolve complaint?',
        romanUrdu: 'Resolve karein?',
      ),
      message: AppText.of(
        context,
        english: 'Mark this complaint as resolved?',
        romanUrdu: 'Is shikayat ko resolved mark karein?',
      ),
      confirmLabel:
          AppText.of(context, english: 'Resolve', romanUrdu: 'Resolve'),
      confirmColor: const Color(0xFF1FAB5D),
      icon: Icons.check_circle_outline,
    );
    if (!confirmed || !mounted) return;

    setState(() => _processingIds.add(complaint.id));
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaint.id)
          .update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      _showSnack(
        context,
        AppText.of(
          context,
          english: 'Complaint resolved',
          romanUrdu: 'Shikayat resolve ho gai',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, e.toString(), background: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _processingIds.remove(complaint.id));
    }
  }

  Future<void> _reopen(BuildContext context, ComplaintRecord complaint) async {
    if (_processingIds.contains(complaint.id)) return;

    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: AppText.of(
        context,
        english: 'Reopen complaint?',
        romanUrdu: 'Dobara open karein?',
      ),
      message: AppText.of(
        context,
        english: 'Move this complaint back to open?',
        romanUrdu: 'Is shikayat ko open par wapas karein?',
      ),
      confirmLabel:
          AppText.of(context, english: 'Reopen', romanUrdu: 'Reopen'),
      confirmColor: const Color(0xFFF59E0B),
      icon: Icons.refresh,
    );
    if (!confirmed || !mounted) return;

    setState(() => _processingIds.add(complaint.id));
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaint.id)
          .update({
        'status': 'open',
        'resolvedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      _showSnack(
        context,
        AppText.of(
          context,
          english: 'Complaint reopened',
          romanUrdu: 'Shikayat dobara open ho gai',
        ),
        background: const Color(0xFFF59E0B),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, e.toString(), background: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _processingIds.remove(complaint.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminFilterChipBar(
          options: const ['Open', 'Resolved'],
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              var complaints = List<ComplaintRecord>.from(widget.complaints);

              if (_filter == 'Open') {
                complaints = complaints.where((c) => c.isOpen).toList();
              } else {
                complaints = complaints.where((c) => c.isResolved).toList();
              }

              complaints = complaints.where((c) {
                return _matchesQuery(widget.searchQuery, [
                  c.userName,
                  c.userEmail,
                  c.mechanicName,
                  c.issue,
                  c.status,
                ]);
              }).toList();

              complaints.sort((a, b) {
                final aDate =
                    a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bDate =
                    b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                return bDate.compareTo(aDate);
              });

              if (complaints.isEmpty) {
                return _EmptyState(
                  icon: Icons.report_outlined,
                  message: AppText.of(
                    context,
                    english: _filter == 'Open'
                        ? 'No open complaints'
                        : 'No resolved complaints',
                    romanUrdu: _filter == 'Open'
                        ? 'Koi open shikayat nahi'
                        : 'Koi resolved shikayat nahi',
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  final processing = _processingIds.contains(complaint.id);

                  return _StyledCard(
                    accentColor: complaint.isResolved
                        ? AdminTheme.success
                        : AdminTheme.warning,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            complaint.mechanicName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AdminTheme.ink,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        AdminStatusChip(
                                          label: complaint.isResolved
                                              ? 'Resolved'
                                              : 'Open',
                                          color: complaint.isResolved
                                              ? AdminTheme.success
                                              : AdminTheme.warning,
                                          icon: complaint.isResolved
                                              ? Icons.check_circle_outline
                                              : Icons.report_outlined,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      AppText.of(
                                        context,
                                        english:
                                            'Reporter: ${complaint.userName}',
                                        romanUrdu:
                                            'Reporter: ${complaint.userName}',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AdminTheme.muted,
                                      ),
                                    ),
                                    if (complaint.userEmail.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        complaint.userEmail,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AdminTheme.muted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            complaint.issue,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(complaint.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AdminTheme.muted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (AdminValidators.isValidEmail(
                                complaint.userEmail,
                              ))
                                _ActionButton(
                                  label: AppText.of(
                                    context,
                                    english: 'Contact',
                                    romanUrdu: 'Contact',
                                  ),
                                  color: AdminTheme.info,
                                  icon: Icons.email_outlined,
                                  onPressed: () => _launchEmail(
                                    context,
                                    complaint.userEmail,
                                  ),
                                ),
                              if (complaint.isOpen)
                                _ActionButton(
                                  label: AppText.of(
                                    context,
                                    english: 'Resolve',
                                    romanUrdu: 'Resolve',
                                  ),
                                  color: AdminTheme.success,
                                  icon: Icons.check,
                                  isLoading: processing,
                                  onPressed: () =>
                                      _resolve(context, complaint),
                                )
                              else
                                _ActionButton(
                                  label: AppText.of(
                                    context,
                                    english: 'Reopen',
                                    romanUrdu: 'Reopen',
                                  ),
                                  color: AdminTheme.warning,
                                  icon: Icons.refresh,
                                  isLoading: processing,
                                  onPressed: () =>
                                      _reopen(context, complaint),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
