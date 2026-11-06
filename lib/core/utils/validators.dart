abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _digit = RegExp(r'\d');

  static String? required(String? value, [String label = 'This field']) =>
      (value == null || value.trim().isEmpty) ? '$label is required' : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    return _email.hasMatch(value.trim()) ? null : 'Enter a valid email address';
  }

  /// The backend expects exactly 10 characters for phone numbers.
  static String? phone(String? value, [String label = 'Phone number']) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '$label is required';
    return digits.length == 10 ? null : '$label must have 10 digits';
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Choose a password';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!_digit.hasMatch(value)) return 'Include at least one number';
    return null;
  }

  static String? Function(String?) matches(String Function() other) =>
      (value) => value == other() ? null : "Passwords don't match";

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    return (uri != null && uri.hasScheme && uri.host.isNotEmpty) ? null : 'Enter a full link starting with https://';
  }

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');
}

/// 0–4 score used by the password strength bar.
int passwordStrength(String value) {
  var score = 0;
  if (value.length >= 8) score++;
  if (RegExp(r'\d').hasMatch(value)) score++;
  if (RegExp('[A-Z]').hasMatch(value) && RegExp('[a-z]').hasMatch(value)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(value) || value.length >= 12) score++;
  return score;
}
