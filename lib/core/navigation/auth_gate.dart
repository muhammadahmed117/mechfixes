import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mechfixes/Admin/admin_dashboard_screen.dart';
import 'package:mechfixes/Customer/customer_home_screen.dart';
import 'package:mechfixes/Mechanic/mechanic_dashboard_screen.dart';
import 'package:mechfixes/Mechanic/mechanic_pending_approval_screen.dart';
import 'package:mechfixes/Mechanic/mechanic_profile_data.dart';
import 'package:mechfixes/Mechanic/mechanic_profile_edit_screen.dart';
import 'package:mechfixes/welcome_screen.dart';

/// Restores the correct home screen when a Firebase session is still active.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _primary = Color(0xFF1F3FAF);

  late final Future<Widget> _homeFuture;

  @override
  void initState() {
    super.initState();
    _homeFuture = _resolveHome();
  }

  Future<Widget> _resolveHome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const WelcomeScreen();

    try {
      final uid = user.uid;
      final email = user.email ?? '';

      final adminDoc =
          await FirebaseFirestore.instance.collection('admins').doc(uid).get();
      if (adminDoc.exists) return const AdminDashboardScreen();

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) return const CustomerHomeScreen();

      final mechanicDoc =
          await FirebaseFirestore.instance.collection('mechanics').doc(uid).get();
      if (!mechanicDoc.exists) {
        // Stale auth session without a profile — clear and show welcome.
        await FirebaseAuth.instance.signOut();
        return const WelcomeScreen();
      }

      final data = mechanicDoc.data() ?? <String, dynamic>{};
      final shopName = (data['shopName'] as String?)?.trim() ?? '';
      final isVerified = data['isVerified'] == true;
      final status =
          (data['status'] as String?)?.trim().toLowerCase() ?? 'pending';
      final isRejected = status == 'rejected';
      final adminNote = (data['adminNote'] as String?)?.trim() ?? '';

      if (shopName.isEmpty) {
        return MechanicProfileEditScreen(
          initialEmail: email,
          isOnboarding: true,
        );
      }

      if (!isVerified || isRejected) {
        return MechanicPendingApprovalScreen(
          isRejected: isRejected,
          adminNote: adminNote,
        );
      }

      return MechanicDashboardScreen(
        profileData: _mechanicProfileFromFirestore(data, email),
      );
    } catch (_) {
      return const WelcomeScreen();
    }
  }

  MechanicProfileData _mechanicProfileFromFirestore(
    Map<String, dynamic> data,
    String fallbackEmail,
  ) {
    final specialties = (data['specialties'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return MechanicProfileData(
      email: data['email'] as String? ?? fallbackEmail,
      shopName: data['shopName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: (data['location'] as String?) ??
          (data['address'] as String?) ??
          '',
      specialties: specialties,
      openingDays: data['openingDays'] as String? ?? '',
      openingHours: data['openingHours'] as String? ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _homeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: _primary),
            ),
          );
        }

        return snapshot.data ?? const WelcomeScreen();
      },
    );
  }
}
