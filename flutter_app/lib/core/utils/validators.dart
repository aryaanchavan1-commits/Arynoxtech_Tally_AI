class Validators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Invalid email';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < 10) return 'Invalid phone number';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? gstin(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length != 15) return 'GSTIN must be 15 characters';
    return null;
  }
}
