import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, romanUrdu }

class AppLanguageController extends ValueNotifier<AppLanguage> {
  AppLanguageController._() : super(AppLanguage.english);

  static final AppLanguageController instance = AppLanguageController._();
  static const _prefsKey = 'app_language';

  bool get isEnglish => value == AppLanguage.english;

  Future<void> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == 'romanUrdu') {
        value = AppLanguage.romanUrdu;
      } else if (saved == 'english') {
        value = AppLanguage.english;
      }
    } catch (error) {
      debugPrint('[AppLanguage] Failed to load saved language: $error');
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (value == language) return;
    value = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        language == AppLanguage.english ? 'english' : 'romanUrdu',
      );
    } catch (error) {
      debugPrint('[AppLanguage] Failed to save language: $error');
    }
  }

  Future<void> toggle() async {
    await setLanguage(
      isEnglish ? AppLanguage.romanUrdu : AppLanguage.english,
    );
  }
}

/// Inherited scope so every screen rebuilds when language changes.
class AppLanguageScope extends InheritedWidget {
  const AppLanguageScope({
    super.key,
    required this.language,
    required super.child,
  });

  final AppLanguage language;

  bool get isEnglish => language == AppLanguage.english;

  static AppLanguageScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'AppLanguageScope not found in widget tree');
    return scope!;
  }

  static AppLanguageScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();
  }

  @override
  bool updateShouldNotify(AppLanguageScope oldWidget) {
    return language != oldWidget.language;
  }
}
