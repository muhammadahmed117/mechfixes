import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/localization/app_language_controller.dart';
import 'core/navigation/auth_gate.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AppLanguageController.instance.loadSaved();

  runApp(const MechfixesApp());
}

class MechfixesApp extends StatelessWidget {
  const MechfixesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mechfixes',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF183DBF),
      ),
      home: const AuthGate(),
      // Rebuild descendants on language change without resetting navigation.
      builder: (context, child) {
        return ValueListenableBuilder<AppLanguage>(
          valueListenable: AppLanguageController.instance,
          builder: (context, language, _) {
            return AppLanguageScope(
              language: language,
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
