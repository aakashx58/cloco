import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_exception.dart';
import '../../core/security/password_hasher.dart';
import '../models/app_user.dart';

/// CRUD for registered users, stored as a JSON list in shared_preferences.
///
/// This is the single source of truth for both login and the dashboard's
/// user management screen.
class UserRepository {
  UserRepository(this._prefs);

  static const storageKey = 'registered_users';

  final SharedPreferences _prefs;
  final Random _random = Random();

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  List<AppUser> getAll() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt data should not lock the admin out of the app.
      return [];
    }
  }

  AppUser? findById(String id) =>
      getAll().where((user) => user.id == id).firstOrNull;

  AppUser? findByEmail(String email) {
    final normalized = normalizeEmail(email);
    return getAll().where((user) => user.email == normalized).firstOrNull;
  }

  bool isEmailTaken(String email, {String? exceptUserId}) {
    final normalized = normalizeEmail(email);
    return getAll().any(
      (user) => user.email == normalized && user.id != exceptUserId,
    );
  }

  Future<AppUser> create({
    required String name,
    required String email,
    required String password,
  }) async {
    if (isEmailTaken(email)) {
      throw const AppException('An account with this email already exists');
    }
    final salt = PasswordHasher.generateSalt();
    final user = AppUser(
      id: _newId(),
      name: name.trim(),
      email: normalizeEmail(email),
      passwordHash: PasswordHasher.hash(password, salt),
      salt: salt,
      createdAt: DateTime.now(),
    );
    await _save([...getAll(), user]);
    return user;
  }

  /// Updates name/email. A null or empty [newPassword] keeps the current one.
  Future<AppUser> update(
    String id, {
    required String name,
    required String email,
    String? newPassword,
  }) async {
    final users = getAll();
    final index = users.indexWhere((user) => user.id == id);
    if (index < 0) throw const AppException('User not found');
    if (isEmailTaken(email, exceptUserId: id)) {
      throw const AppException('An account with this email already exists');
    }

    var updated = users[index].copyWith(
      name: name.trim(),
      email: normalizeEmail(email),
    );
    if (newPassword != null && newPassword.isNotEmpty) {
      final salt = PasswordHasher.generateSalt();
      updated = updated.copyWith(
        salt: salt,
        passwordHash: PasswordHasher.hash(newPassword, salt),
      );
    }
    users[index] = updated;
    await _save(users);
    return updated;
  }

  Future<void> delete(String id) async {
    await _save(getAll()..removeWhere((user) => user.id == id));
  }

  Future<void> _save(List<AppUser> users) async {
    final saved = await _prefs.setString(
      storageKey,
      jsonEncode(users.map((user) => user.toJson()).toList()),
    );
    if (!saved) throw const AppException('Could not save to local storage');
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_random.nextInt(1 << 20).toRadixString(36)}';
}
