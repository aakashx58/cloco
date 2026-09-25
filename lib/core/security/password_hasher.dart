import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 hashing so plain-text passwords never reach
/// shared_preferences (which is an unencrypted file on disk).
class PasswordHasher {
  const PasswordHasher._();

  static String generateSalt([int length = 16]) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  static bool verify(
    String password, {
    required String salt,
    required String hash,
  }) => PasswordHasher.hash(password, salt) == hash;
}
