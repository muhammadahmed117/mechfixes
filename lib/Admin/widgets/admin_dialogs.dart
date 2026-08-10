import 'package:flutter/material.dart';
import 'package:mechfixes/core/admin/admin_validators.dart';
import 'package:mechfixes/core/localization/app_text.dart';

Future<bool> showAdminConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  Color confirmColor = const Color(0xFF3B82F6),
  IconData icon = Icons.help_outline,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: confirmColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              cancelLabel ??
                  AppText.of(ctx, english: 'Cancel', romanUrdu: 'Cancel'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel ??
                  AppText.of(ctx, english: 'Confirm', romanUrdu: 'Confirm'),
            ),
          ),
        ],
      );
    },
  );
  return result == true;
}

Future<String?> showAdminReasonDialog({
  required BuildContext context,
  required String title,
  String? hint,
  String? confirmLabel,
  Color confirmColor = const Color(0xFFFF4D4F),
}) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: hint ??
                  AppText.of(
                    ctx,
                    english: 'Enter reason…',
                    romanUrdu: 'Wajah likhein…',
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: AdminValidators.validateAdminNote,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppText.of(ctx, english: 'Cancel', romanUrdu: 'Cancel'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx, controller.text.trim());
            },
            child: Text(
              confirmLabel ??
                  AppText.of(ctx, english: 'Submit', romanUrdu: 'Submit'),
            ),
          ),
        ],
      );
    },
  );

  controller.dispose();
  return result;
}
