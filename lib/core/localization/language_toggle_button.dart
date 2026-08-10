import 'package:flutter/material.dart';
import 'package:mechfixes/core/localization/app_language_controller.dart';
import 'package:mechfixes/core/localization/app_text.dart';

/// Shared language toggle used across app bars and headers.
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({
    super.key,
    this.compact = false,
    this.foregroundColor = Colors.white,
  });

  final bool compact;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final label = AppText.isEnglishOf(context) ? 'Roman Urdu' : 'English';

    if (compact) {
      return IconButton(
        tooltip: label,
        onPressed: () => AppLanguageController.instance.toggle(),
        icon: Icon(Icons.translate, color: foregroundColor, size: 20),
      );
    }

    return TextButton.icon(
      onPressed: () => AppLanguageController.instance.toggle(),
      icon: Icon(Icons.translate, color: foregroundColor, size: 18),
      label: Text(
        label,
        style: TextStyle(color: foregroundColor, fontSize: 12),
      ),
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
