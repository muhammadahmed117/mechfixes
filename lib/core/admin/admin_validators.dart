/// Shared validation helpers for Admin Portal actions.
class AdminValidators {
  AdminValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneDigits = RegExp(r'[0-9+]');

  /// Reject / block reason must be meaningful (min 5 chars).
  static String? validateAdminNote(String? value, {int minLength = 5}) {
    final note = value?.trim() ?? '';
    if (note.isEmpty) {
      return 'Please provide a reason';
    }
    if (note.length < minLength) {
      return 'Reason must be at least $minLength characters';
    }
    return null;
  }

  static bool isValidEmail(String? email) {
    final value = email?.trim() ?? '';
    if (value.isEmpty) return false;
    return _emailRegex.hasMatch(value);
  }

  /// Returns a dialable phone string, or null if too short / invalid.
  static String? normalizePhone(String? phone) {
    final raw = phone?.trim() ?? '';
    if (raw.isEmpty) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    final digitsOnly = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7) return null;
    return cleaned;
  }

  static bool isValidPhone(String? phone) => normalizePhone(phone) != null;

  static bool hasPhoneDigits(String? phone) {
    final raw = phone?.trim() ?? '';
    return _phoneDigits.hasMatch(raw);
  }
}
