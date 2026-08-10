import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mechfixes/core/localization/app_text.dart';
import 'package:mechfixes/core/localization/language_toggle_button.dart';
import 'package:mechfixes/login_screen.dart';

/// Shown after mechanic signup / login until an admin verifies the account.
class MechanicPendingApprovalScreen extends StatelessWidget {
  const MechanicPendingApprovalScreen({
    super.key,
    this.adminNote = '',
    this.isRejected = false,
  });

  final String adminNote;
  final bool isRejected;

  static const _primary = Color(0xFF1F3FAF);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isRejected
        ? AppText.of(
            context,
            english: 'Application rejected',
            romanUrdu: 'Application reject ho gai',
          )
        : AppText.of(
            context,
            english: 'Waiting for admin approval',
            romanUrdu: 'Admin approval ka intezar',
          );

    final message = isRejected
        ? AppText.of(
            context,
            english:
                'Your mechanic account was not approved. Contact support or update your details and wait for review.',
            romanUrdu:
                'Aapka mechanic account approve nahi hua. Support se rabta karein ya details update karke review ka wait karein.',
          )
        : AppText.of(
            context,
            english:
                'Your account was created, but customers will see you only after an admin verifies your shop. You can close the app and sign in again later.',
            romanUrdu:
                'Account ban gaya hai, lekin customers tabhi dekhein ge jab admin aapki shop verify kare. Baad mein dubara sign in kar sakte hain.',
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          AppText.of(
            context,
            english: 'Mechfixes Mechanic',
            romanUrdu: 'Mechfixes Mechanic',
          ),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: const [LanguageToggleButton(compact: true)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: (isRejected
                          ? const Color(0xFFF04438)
                          : const Color(0xFFF79009))
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected
                      ? Icons.cancel_outlined
                      : Icons.hourglass_top_rounded,
                  size: 42,
                  color: isRejected
                      ? const Color(0xFFF04438)
                      : const Color(0xFFF79009),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF667085),
                ),
              ),
              if (adminNote.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD0D5DD)),
                  ),
                  child: Text(
                    AppText.of(
                      context,
                      english: 'Admin note: $adminNote',
                      romanUrdu: 'Admin note: $adminNote',
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF344054),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppText.of(
                      context,
                      english: 'Back to login',
                      romanUrdu: 'Login par wapas',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
