import 'package:bloc_test/bloc_test.dart';
import 'package:cloco/data/repositories/auth_repository.dart';
import 'package:cloco/data/repositories/user_repository.dart';
import 'package:cloco/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late UserRepository users;
  late AuthRepository auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    users = UserRepository(prefs);
    auth = AuthRepository(prefs, users);
  });

  Future<void> seedAdmin() => users.create(
    name: 'Admin User',
    email: 'Admin@Test.com ',
    password: 'secret1',
  );

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'is Unauthenticated on start when there is no session',
      build: () => AuthBloc(auth),
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const Unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'restores the session on start when already logged in',
      setUp: () async {
        await seedAdmin();
        await auth.login(email: 'admin@test.com', password: 'secret1');
      },
      build: () => AuthBloc(auth),
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [isA<Authenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'registration succeeds without logging the user in',
      build: () => AuthBloc(auth),
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          name: 'New Admin',
          email: 'new@test.com',
          password: 'secret1',
        ),
      ),
      expect: () => [const AuthLoading(), const AuthRegistered('new@test.com')],
      verify: (_) async => expect(await auth.currentUser(), isNull),
    );

    blocTest<AuthBloc, AuthState>(
      'registration fails for an email that already exists',
      setUp: seedAdmin,
      build: () => AuthBloc(auth),
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          name: 'Copy',
          email: 'ADMIN@test.com',
          password: 'secret1',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthFailure('An account with this email already exists'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'logs in with valid credentials (email is case-insensitive)',
      setUp: seedAdmin,
      build: () => AuthBloc(auth),
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: ' ADMIN@test.com', password: 'secret1'),
      ),
      expect: () => [const AuthLoading(), isA<Authenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'rejects a wrong password',
      setUp: seedAdmin,
      build: () => AuthBloc(auth),
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'admin@test.com',
          password: 'wrong-password',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthFailure('Invalid email or password'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'logout clears the session',
      setUp: () async {
        await seedAdmin();
        await auth.login(email: 'admin@test.com', password: 'secret1');
      },
      build: () => AuthBloc(auth),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [const Unauthenticated()],
      verify: (_) async => expect(await auth.currentUser(), isNull),
    );
  });

  group('UserRepository', () {
    test('never stores the plain-text password', () async {
      await seedAdmin();
      final raw = prefs.getString(UserRepository.storageKey)!;
      expect(raw, isNot(contains('secret1')));
    });

    test('update keeps the password when none is given', () async {
      await seedAdmin();
      final user = users.findByEmail('admin@test.com')!;
      await users.update(user.id, name: 'Renamed', email: 'renamed@test.com');

      final login = await auth.login(
        email: 'renamed@test.com',
        password: 'secret1',
      );
      expect(login.name, 'Renamed');
    });

    test('a deleted user loses their session', () async {
      await seedAdmin();
      final user = await auth.login(
        email: 'admin@test.com',
        password: 'secret1',
      );
      await users.delete(user.id);
      expect(await auth.currentUser(), isNull);
    });
  });
}
