class Validators {
  static String? email(String value) {
    if (value.trim().isEmpty) return 'Email is required.';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) return 'Enter a valid email.';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Password is required.';
    if (value.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  static String? requiredText(String value, String label) {
    if (value.trim().isEmpty) return '$label is required.';
    return null;
  }
}
