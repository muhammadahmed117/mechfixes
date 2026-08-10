import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mechfixes/core/localization/app_language_controller.dart';
import 'package:mechfixes/core/localization/app_text.dart';

import 'create_account.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final Timer _featureTimer;
  int _activeFeatureIndex = 0;

  static const List<({IconData icon, String title, String subtitle})>
  _features = [
    (
      icon: Icons.build_outlined,
      title: 'Smart Diagnosis',
      subtitle: 'AI-powered issue detection for accurate results',
    ),
    (
      icon: Icons.location_on_outlined,
      title: 'Find Mechanics',
      subtitle: 'Locate trusted professionals near you',
    ),
    (
      icon: Icons.star_border_rounded,
      title: 'Verified Ratings',
      subtitle: 'Read reviews from real customers',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _featureTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _activeFeatureIndex = (_activeFeatureIndex + 1) % _features.length;
      });
    });
  }

  @override
  void dispose() {
    _featureTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageController.instance,
      builder: (context, _, __) {
        final title = AppText.of(
          context,
          english:
              'Your intelligent vehicle diagnostic companion. Find issues, get expert help, and connect with trusted mechanics instantly.',
          romanUrdu:
              'Aap ki smart vehicle diagnostic app. Maslay samjhein, expert help lein, aur bharosemand mechanics se foran connect karein.',
        );
        final featureCards = [
          (
            icon: Icons.build_outlined,
            title: AppText.of(
              context,
              english: 'Smart Diagnosis',
              romanUrdu: 'Smart Tashkhees',
            ),
            subtitle: AppText.of(
              context,
              english: 'AI-powered issue detection for accurate results',
              romanUrdu: 'Sahi natijon ke liye AI se issue detection',
            ),
          ),
          (
            icon: Icons.location_on_outlined,
            title: AppText.of(
              context,
              english: 'Find Mechanics',
              romanUrdu: 'Mechanic Dhoondein',
            ),
            subtitle: AppText.of(
              context,
              english: 'Locate trusted professionals near you',
              romanUrdu: 'Apne qareeb bharosemand mechanics dhoondein',
            ),
          ),
          (
            icon: Icons.star_border_rounded,
            title: AppText.of(
              context,
              english: 'Verified Ratings',
              romanUrdu: 'Verified Ratings',
            ),
            subtitle: AppText.of(
              context,
              english: 'Read reviews from real customers',
              romanUrdu: 'Asal customers ke reviews parhein',
            ),
          ),
        ];
        final feature = featureCards[_activeFeatureIndex];

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E43C8), Color(0xFF1B3FBE), Color(0xFF183AB2)],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: -120,
                    right: -90,
                    child: _decorOrb(size: 280, color: const Color(0xFF92A7FF)),
                  ),
                  Positioned(
                    left: -70,
                    bottom: -90,
                    child: _decorOrb(size: 220, color: const Color(0xFF6D86F0)),
                  ),
                  Positioned(
                    top: 8,
                    right: 16,
                    child: _LanguageToggle(
                      label: AppText.isEnglish ? 'Roman Urdu' : 'English',
                      onTap: AppLanguageController.instance.toggle,
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compactHeight = constraints.maxHeight < 720;
                      final veryCompactHeight = constraints.maxHeight < 600;
                      final buttonHeight = veryCompactHeight ? 46.0 : 54.0;
                      final iconSize = veryCompactHeight ? 52.0 : 66.0;
                      final titleSize = veryCompactHeight ? 42.0 : 52.0;
                      final subtitleSize = compactHeight ? 15.0 : 17.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: iconSize,
                                    width: iconSize,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.18),
                                          blurRadius: 26,
                                          offset: const Offset(0, 14),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.directions_car_outlined,
                                      color: const Color(0xFF1F3FAF),
                                      size: veryCompactHeight ? 28 : 34,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Mechfixes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    maxLines: veryCompactHeight ? 1 : 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.92),
                                      fontSize: subtitleSize,
                                      height: 1.4,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 700),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, animation) {
                                        final slide = Tween<Offset>(
                                          begin: const Offset(0.08, 0),
                                          end: Offset.zero,
                                        ).animate(animation);
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: slide,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _buildFeatureCard(
                                        key: ValueKey<String>(
                                          '$_activeFeatureIndex-${AppText.isEnglish}',
                                        ),
                                        icon: feature.icon,
                                        title: feature.title,
                                        subtitle: feature.subtitle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(featureCards.length, (index) {
                                      final selected = index == _activeFeatureIndex;
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: selected ? 18 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? Colors.white
                                              : Colors.white.withValues(alpha: 0.40),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const CreateAccountScreen(
                                              initialIsUser: true,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE9E9EC),
                                        foregroundColor: const Color(0xFF1B3DB7),
                                        elevation: 0,
                                        minimumSize: Size.fromHeight(buttonHeight),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        AppText.of(
                                          context,
                                          english: 'Get Started',
                                          romanUrdu: 'Shuru Karein',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const LoginScreen(),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        minimumSize: Size.fromHeight(buttonHeight),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        AppText.of(
                                          context,
                                          english: 'Sign In',
                                          romanUrdu: 'Sign In',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (!veryCompactHeight)
                                    Text(
                                      AppText.of(
                                        context,
                                        english: '© 2025 Mechfixes. All rights reserved.',
                                        romanUrdu: '© 2025 Mechfixes. Tamam huqooq mehfooz hain.',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _decorOrb({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    Key? key,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF6F87E8).withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.translate, color: Colors.white, size: 18),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
