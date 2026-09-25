import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_exception.dart';
import '../../core/security/password_hasher.dart';
import '../models/app_user.dart';
import 'user_repository.dart';

/// Login/logout against users stored by [UserRepository].
///
/// The session is just the logged-in user's id. Storing the id (not the
/// email) means an admin can change their own email without being logged out.
class AuthRepository {
  AuthRepository(this._prefs, this._users);

  static const sessionKey = 'session_user_id';

  final SharedPreferences _prefs;
  final UserRepository _users;

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) => _users.create(name: name, email: email, password: password);

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final user = _users.findByEmail(email);
    final valid =
        user != null &&
        PasswordHasher.verify(
          password,
          salt: user.salt,
          hash: user.passwordHash,
        );
    // Same message for unknown email and wrong password, so the login form
    // does not reveal which emails are registered.
    if (!valid) throw const AppException('Invalid email or password');

    await _prefs.setString(sessionKey, user.id);
    return user;
  }

  /// The logged-in user, or null. Clears a session whose user was deleted.
  Future<AppUser?> currentUser() async {
    final id = _prefs.getString(sessionKey);
    if (id == null) return null;
    final user = _users.findById(id);
    if (user == null) await _prefs.remove(sessionKey);
    return user;
  }

  Future<void> logout() async {
    await _prefs.remove(sessionKey);
  }
}
