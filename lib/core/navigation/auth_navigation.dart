import 'package:flutter/material.dart';
import 'package:mechfixes/login_screen.dart';
import 'package:mechfixes/services/mechanic_auth_service.dart';

Future<void> logoutToLogin(BuildContext context) async {
  await MechanicAuthService.instance.signOut();

  if (!context.mounted) return;

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}
