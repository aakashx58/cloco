import 'package:cloco/app.dart';
import 'package:cloco/core/di/injection.dart';
import 'package:cloco/data/repositories/auth_repository.dart';
import 'package:cloco/data/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_api_adapter.dart';

/// End-to-end widget test of the real app: DI container, go_router guards,
/// blocs, Dio configuration and screens — only the HTTP transport is faked.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies(httpAdapter: fakeDummyJson());
  });

  Future<void> enter(WidgetTester tester, String label, String text) =>
      tester.enterText(find.widgetWithText(TextFormField, label), text);

  /// Scrolls the button into view first, as a user would on a small screen.
  Future<void> tapButton(WidgetTester tester, String label) async {
    final button = find.widgetWithText(FilledButton, label);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('register → login → dashboard → detail → users → logout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProductManagerApp());
    await tester.pumpAndSettle();

    // No session → auth guard lands on login (spec 3.1.1).
    expect(find.text('Welcome back'), findsOneWidget);

    // Register a new admin.
    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsWidgets);

    await enter(tester, 'Full name', 'Jane Admin');
    await enter(tester, 'Email', 'jane@test.com');
    await enter(tester, 'Password', 'secret1');
    await enter(tester, 'Confirm password', 'secret1');
    await tapButton(tester, 'Create account');

    // Back on login with the email prefilled, not logged in.
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('jane@test.com'), findsOneWidget);
    expect(find.text('Account created! Please sign in.'), findsOneWidget);

    // Wrong password is rejected.
    await enter(tester, 'Password', 'nope123');
    await tapButton(tester, 'Sign in');
    expect(find.text('Invalid email or password'), findsOneWidget);

    // Correct login → dashboard with products from the API.
    await enter(tester, 'Password', 'secret1');
    await tapButton(tester, 'Sign in');
    expect(find.text('Welcome back, Jane'), findsOneWidget);
    expect(find.text('Phone X'), findsOneWidget);
    expect(find.text('Laptop Pro'), findsOneWidget);
    expect(find.text('2 products'), findsOneWidget);

    // Product detail via /products/:id.
    await tester.tap(find.text('Phone X'));
    await tester.pumpAndSettle();
    expect(find.text('Phone X description'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Edit'), findsOneWidget);

    // Back to the list, then the Users tab lists the registered admin.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Users').last);
    await tester.pumpAndSettle();
    expect(find.text('Jane Admin'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);

    // Logout → auth guard returns to login.
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out').last);
    await tester.pumpAndSettle();
    await tapButton(tester, 'Log out');
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('an existing session skips login (spec 3.1.2)', (tester) async {
    // Seed a user + session through the real repositories.
    await getIt<UserRepository>().create(
      name: 'Sam Saved',
      email: 'sam@test.com',
      password: 'secret1',
    );
    await getIt<AuthRepository>().login(
      email: 'sam@test.com',
      password: 'secret1',
    );

    await tester.pumpWidget(const ProductManagerApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Welcome back, Sam'), findsOneWidget);
    expect(find.text('Phone X'), findsOneWidget);
  });
}
