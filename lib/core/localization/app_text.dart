import 'package:flutter/widgets.dart';

import 'app_language_controller.dart';

class AppText {
  AppText._();

  static bool isEnglishOf(BuildContext context) {
    final scope = AppLanguageScope.maybeOf(context);
    if (scope != null) return scope.isEnglish;
    return AppLanguageController.instance.isEnglish;
  }

  static bool get isEnglish => AppLanguageController.instance.isEnglish;

  /// Returns English or Roman Urdu based on the current global language.
  /// Calling this from a widget's build method registers a language dependency.
  static String of(
    BuildContext context, {
    required String english,
    required String romanUrdu,
  }) {
    return isEnglishOf(context) ? english : romanUrdu;
  }
}
