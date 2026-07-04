import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mechfixes/Admin/admin_dashboard_screen.dart';
import 'package:mechfixes/Customer/customer_home_screen.dart';
import 'package:mechfixes/Mechanic/mechanic_dashboard_screen.dart';
import 'package:mechfixes/Mechanic/mechanic_profile_data.dart';
import 'package:mechfixes/Mechanic/mechanic_profile_edit_screen.dart';
import 'package:mechfixes/services/auth_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialIsUser = true});

  final bool initialIsUser;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _primary = Color(0xFF1F3FAF);

  // ── State ──
  late bool isUser;   // top toggle:    User | Mechanic
  bool isLogin = true; // bottom toggle: Sign In | Sign Up
  bool _isLoading = false;
  bool _obscure = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isUser = widget.initialIsUser;
    // Kill any persisted Firebase session immediately.
    FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Master submit — 4 user paths + admin interceptor ───────────────────

  Future<void> _submitAuth() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        // ── Sign In: authenticate first, then check admin ──
        if (isUser) {
          await AuthService().signInUser(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        } else {
          await AuthService().signInMechanic(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        }

        // ── Admin interceptor (runs for every successful login) ──
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(uid)
            .get();

        if (!mounted) return;

        if (adminDoc.exists) {
          // Confirmed admin — route to Admin Dashboard regardless of toggle
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
          return;
        }

        // ── Regular routing after admin check ──
        if (isUser) {
          // Path 1: User Sign In → Customer home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
          );
        } else {
          // Path 3: Mechanic Sign In → dashboard or onboarding
          final mechanicDoc = await FirebaseFirestore.instance
              .collection('mechanics')
              .doc(uid)
              .get();
          final data = mechanicDoc.data() ?? {};
          final shopName = (data['shopName'] as String?)?.trim() ?? '';

          if (!mounted) return;

          if (shopName.isNotEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MechanicDashboardScreen(
                  profileData: _mechanicProfileFromFirestore(
                    data,
                    _emailController.text.trim(),
                  ),
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MechanicProfileEditScreen(
                  initialEmail: _emailController.text.trim(),
                  isOnboarding: true,
                ),
              ),
            );
          }
        }
      } else {
        // ── Sign Up paths (no admin check — admins are backend-only) ──
        if (isUser) {
          // Path 2: User Sign Up
          await AuthService().signUpUser(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
          );
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
          );
        } else {
          // Path 4: Mechanic Sign Up
          await AuthService().signUpMechanic(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
          );
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MechanicProfileEditScreen(
                initialEmail: _emailController.text.trim(),
                isOnboarding: true,
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Firebase failed — show error, NEVER navigate
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar
                Container(
                  height: 52,
                  width: double.infinity,
                  color: _primary,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InkWell(
                    onTap: _isLoading ? null : () => Navigator.pop(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('Back', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 30,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 10),

                              // ── Logo ──
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 42,
                                    width: 42,
                                    decoration: BoxDecoration(
                                      color: _primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Mechfixes',
                                    style: TextStyle(color: _primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              Text(
                                isLogin ? 'Welcome Back' : 'Create Account',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isLogin
                                    ? 'Sign in to continue'
                                    : 'Fill in the details below',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 20),

                              // ── User / Mechanic toggle ──
                              _segmentedToggle(
                                leftLabel: 'User',
                                rightLabel: 'Mechanic',
                                leftSelected: isUser,
                                onLeft: () => setState(() {
                                  isUser = true;
                                  _formKey.currentState?.reset();
                                }),
                                onRight: () => setState(() {
                                  isUser = false;
                                  _formKey.currentState?.reset();
                                }),
                              ),
                              const SizedBox(height: 20),

                              // ── Full Name (sign-up only) ──
                              if (!isLogin) ...[
                                _label('Full Name'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  enabled: !_isLoading,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: _inputDeco('John Doe'),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Full name is required.';
                                    }
                                    if (v.trim().length < 2) {
                                      return 'Name must be at least 2 characters.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),
                              ],

                              // ── Email ──
                              _label('Email Address'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                enabled: !_isLoading,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: _inputDeco('you@example.com'),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Email is required.';
                                  }
                                  final ok = RegExp(
                                    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                                  ).hasMatch(v.trim());
                                  return ok ? null : 'Enter a valid email address.';
                                },
                              ),
                              const SizedBox(height: 15),

                              // ── Password ──
                              _label('Password'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submitAuth(),
                                enabled: !_isLoading,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: _inputDeco(
                                  isLogin ? 'Enter your password' : 'Min. 6 characters',
                                  suffixIcon: IconButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Password is required.';
                                  }
                                  if (!isLogin && v.length < 6) {
                                    return 'Password must be at least 6 characters.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // ── Primary button ──
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitAuth,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    disabledBackgroundColor: const Color(0xFF98A2B3),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          isLogin ? 'Sign In' : 'Create Account',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // ── Bottom toggle: Sign In ↔ Sign Up ──
                              // ONLY calls setState — never pushes a new screen.
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLogin
                                        ? "Don't have an account? "
                                        : 'Already have an account? ',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  GestureDetector(
                                    onTap: _isLoading
                                        ? null
                                        : () => setState(() {
                                              isLogin = !isLogin;
                                              _formKey.currentState?.reset();
                                              _nameController.clear();
                                              _emailController.clear();
                                              _passwordController.clear();
                                            }),
                                    child: Text(
                                      isLogin ? 'Sign Up' : 'Sign In',
                                      style: const TextStyle(
                                        color: _primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Loading overlay
            if (_isLoading)
              const ColoredBox(
                color: Color(0x44000000),
                child: Center(
                  child: CircularProgressIndicator(color: _primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

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

  Widget _segmentedToggle({
    required String leftLabel,
    required String rightLabel,
    required bool leftSelected,
    required VoidCallback onLeft,
    required VoidCallback onRight,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE4E7EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleTab(leftLabel, selected: leftSelected, onTap: onLeft),
          _toggleTab(rightLabel, selected: !leftSelected, onTap: onRight),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, {required bool selected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: _isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? _primary : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      );

  InputDecoration _inputDeco(String hint, {Widget? suffixIcon}) => InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      );
}
