import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mechfixes/Customer/customer_home_screen.dart';
import 'package:mechfixes/Mechanic/mechanic_dashboard_screen.dart';
import 'package:mechfixes/Mechanic/mechanic_profile_data.dart';
import 'package:mechfixes/Mechanic/mechanic_profile_edit_screen.dart';
import 'package:mechfixes/core/auth/auth_validators.dart';
import 'package:mechfixes/services/auth_service.dart';
import 'package:mechfixes/services/mechanic_auth_service.dart';

import 'login_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key, this.initialIsUser = true});

  final bool initialIsUser;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  late bool isUser;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool termsAccepted = false;
  bool isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final MechanicAuthService _authService = MechanicAuthService.instance;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool get _canCreateAccount {
    return fullNameController.text.trim().isNotEmpty &&
        AuthValidators.validateEmail(emailController.text.trim()) == null &&
        AuthValidators.validatePassword(
              passwordController.text,
              isSignUp: true,
            ) ==
            null &&
        confirmPasswordController.text == passwordController.text &&
        termsAccepted;
  }

  @override
  void initState() {
    super.initState();
    isUser = widget.initialIsUser;
    fullNameController.addListener(_handleFormChanged);
    emailController.addListener(_handleFormChanged);
    passwordController.addListener(_handleFormChanged);
    confirmPasswordController.addListener(_handleFormChanged);
  }

  void _handleFormChanged() {
    setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate() || !termsAccepted) {
      if (!termsAccepted) {
        _showMessage('Please accept the Terms of Service and Privacy Policy.');
      }
      return;
    }

    if (isUser) {
      setState(() => isLoading = true);

      try {
        await AuthService().signUpUser(
          emailController.text.trim(),
          passwordController.text,
          fullNameController.text.trim(),
        );

        if (!mounted) return;

        _showMessage('Account created successfully');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
        );
      } on FirebaseAuthException catch (error) {
        if (!mounted) return;
        _showMessage(error.message ?? 'Could not create account.');
      } catch (error) {
        if (!mounted) return;
        _showMessage(
          error.toString().replaceAll('Exception: ', ''),
        );
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await _authService.signUpWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: fullNameController.text.trim(),
      );

      if (!mounted) return;

      _showMessage('Account created successfully');

      if (result.needsOnboarding) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MechanicProfileEditScreen(
              initialEmail: result.profile.email,
              isOnboarding: true,
            ),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MechanicDashboardScreen(
            profileData: MechanicProfileData(
              email: result.profile.email,
              shopName: result.profile.shopName,
            ),
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message ?? 'Could not create account.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not create account. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    fullNameController.removeListener(_handleFormChanged);
    emailController.removeListener(_handleFormChanged);
    passwordController.removeListener(_handleFormChanged);
    confirmPasswordController.removeListener(_handleFormChanged);
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 52,
                  width: double.infinity,
                  color: const Color(0xFF1F3FAF),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InkWell(
                    onTap: isLoading ? null : () => Navigator.pop(context),
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
                    child: Padding(
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
                              children: [
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 42,
                                      width: 42,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1F3FAF),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.directions_car_outlined,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Mechfixes',
                                      style: TextStyle(
                                        color: Color(0xFF1F3FAF),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0E1B4D),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Join us to get started with vehicle care',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF4F5B7A),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE4E7EC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: isLoading
                                              ? null
                                              : () => setState(() => isUser = true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isUser
                                                  ? Colors.white
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Center(child: Text('User')),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: isLoading
                                              ? null
                                              : () => setState(() => isUser = false),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: !isUser
                                                  ? Colors.white
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Center(
                                              child: Text('Mechanic'),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildLabel('Full Name'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: fullNameController,
                                  hint: 'John Doe',
                                  obscureText: false,
                                  validator: AuthValidators.validateFullName,
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Email Address'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: emailController,
                                  hint: 'you@example.com',
                                  obscureText: false,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: AuthValidators.validateEmail,
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Password'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: passwordController,
                                  hint: 'Create a strong password',
                                  obscureText: obscurePassword,
                                  suffixIcon: obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  onSuffixTap: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                  validator: (value) =>
                                      AuthValidators.validatePassword(
                                    value,
                                    isSignUp: true,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Confirm Password'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: confirmPasswordController,
                                  hint: 'Re-enter your password',
                                  obscureText: obscureConfirmPassword,
                                  suffixIcon: obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  onSuffixTap: () {
                                    setState(() {
                                      obscureConfirmPassword =
                                          !obscureConfirmPassword;
                                    });
                                  },
                                  validator: (value) =>
                                      AuthValidators.validateConfirmPassword(
                                    value,
                                    passwordController.text,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: termsAccepted,
                                      activeColor: const Color(0xFF1F3FAF),
                                      onChanged: isLoading
                                          ? null
                                          : (value) {
                                              setState(() {
                                                termsAccepted = value ?? false;
                                              });
                                            },
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: RichText(
                                          text: const TextSpan(
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF4F5B7A),
                                            ),
                                            children: [
                                              TextSpan(text: 'I agree to the '),
                                              TextSpan(
                                                text: 'Terms of Service',
                                                style: TextStyle(
                                                  color: Color(0xFF1F3FAF),
                                                ),
                                              ),
                                              TextSpan(text: ' and '),
                                              TextSpan(
                                                text: 'Privacy Policy',
                                                style: TextStyle(
                                                  color: Color(0xFF1F3FAF),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _canCreateAccount && !isLoading
                                        ? _createAccount
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1F3FAF),
                                      disabledBackgroundColor:
                                          const Color(0xFFE4E7EC),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Create Account',
                                      style: TextStyle(
                                        color: _canCreateAccount && !isLoading
                                            ? Colors.white
                                            : const Color(0xFF98A2B3),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                InkWell(
                                  onTap: isLoading
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => LoginScreen(
                                                initialIsUser: isUser,
                                              ),
                                            ),
                                          );
                                        },
                                  child: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF4F5B7A),
                                      ),
                                      children: [
                                        TextSpan(text: 'Already have an account? '),
                                        TextSpan(
                                          text: 'Sign in',
                                          style: TextStyle(
                                            color: Color(0xFF1F3FAF),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isLoading)
              const ColoredBox(
                color: Color(0x33000000),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF1F3FAF)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0E1B4D),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: !isLoading,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9AA3B2),
          fontSize: 14,
        ),
        suffixIcon: suffixIcon != null
            ? IconButton(
                onPressed: isLoading ? null : onSuffixTap,
                icon: Icon(
                  suffixIcon,
                  color: const Color(0xFF94A0B8),
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFD6DBE5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF1F3FAF),
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
