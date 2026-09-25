class Validators {
  const Validators._();

  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? name(String? value) {
    final error = required(value, field: 'Name');
    if (error != null) return error;
    if (value!.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? email(String? value) {
    final error = required(value, field: 'Email');
    if (error != null) return error;
    return _emailPattern.hasMatch(value!.trim())
        ? null
        : 'Enter a valid email address';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  /// Password that may be left blank (e.g. "keep current password").
  static String? optionalPassword(String? value) {
    if (value == null || value.isEmpty) return null;
    return password(value);
  }

  static String? price(String? value) {
    final error = required(value, field: 'Price');
    if (error != null) return error;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return 'Price must be greater than 0';
    return null;
  }

  static String? discount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0 || parsed >= 100) return 'Must be between 0 and 99';
    return null;
  }

  static String? stock(String? value) {
    final error = required(value, field: 'Stock');
    if (error != null) return error;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null || parsed < 0) return 'Enter a whole number (0 or more)';
    return null;
  }

  static String? optionalUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    final valid =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid ? null : 'Enter a valid http(s) URL';
  }
}
