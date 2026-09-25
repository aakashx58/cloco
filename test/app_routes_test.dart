import 'package:cloco/core/router/app_routes.dart';
import 'package:cloco/data/models/app_user.dart';
import 'package:cloco/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final user = AppUser(
    id: '1',
    name: 'Admin',
    email: 'admin@test.com',
    passwordHash: 'h',
    salt: 's',
    createdAt: DateTime(2026),
  );

  String? redirect(AuthState auth, String location) =>
      AppRoutes.redirect(auth, Uri.parse(location));

  group('before the session is checked', () {
    test('sends protected pages to splash, remembering the target', () {
      expect(
        redirect(const AuthInitial(), '/products/5'),
        '/splash?from=%2Fproducts%2F5',
      );
    });

    test('stays on splash', () {
      expect(redirect(const AuthInitial(), '/splash'), isNull);
    });
  });

  group('signed out', () {
    test('protected pages go to login with a return path', () {
      expect(
        redirect(const Unauthenticated(), '/users'),
        '/login?from=%2Fusers',
      );
    });

    test('login and register are allowed (also while loading/failed)', () {
      expect(redirect(const Unauthenticated(), '/login'), isNull);
      expect(redirect(const AuthLoading(), '/login/register'), isNull);
      expect(redirect(const AuthFailure('x'), '/login'), isNull);
      expect(redirect(const AuthRegistered('a@b.c'), '/login'), isNull);
    });

    test('splash forwards to login and keeps the return path', () {
      expect(
        redirect(const Unauthenticated(), '/splash?from=%2Fusers'),
        '/login?from=%2Fusers',
      );
    });
  });

  group('signed in', () {
    test('splash and login go to the dashboard (spec 3.1.2)', () {
      expect(redirect(Authenticated(user), '/splash'), '/products');
      expect(redirect(Authenticated(user), '/login'), '/products');
    });

    test('returns to the originally requested page', () {
      expect(
        redirect(Authenticated(user), '/login?from=%2Fproducts%2F5'),
        '/products/5',
      );
    });

    test('ignores unsafe or looping return paths', () {
      expect(
        redirect(Authenticated(user), '/login?from=https%3A%2F%2Fevil.com'),
        '/products',
      );
      expect(
        redirect(Authenticated(user), '/login?from=%2F%2Fevil.com'),
        '/products',
      );
      expect(
        redirect(Authenticated(user), '/login?from=%2Flogin'),
        '/products',
      );
    });

    test('protected pages are allowed', () {
      expect(redirect(Authenticated(user), '/users'), isNull);
      expect(redirect(Authenticated(user), '/products/5/edit'), isNull);
    });
  });
}
