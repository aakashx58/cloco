import 'package:cloco/app.dart';
import 'package:cloco/core/di/injection.dart';
import 'package:cloco/core/utils/responsive.dart';
import 'package:cloco/data/repositories/auth_repository.dart';
import 'package:cloco/data/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_api_adapter.dart';

/// Logical screen sizes covering the device classes the app must handle.
const _screens = {
  'small phone': Size(320, 640),
  'phone': Size(390, 844),
  'landscape phone': Size(844, 390),
  'tablet': Size(820, 1180),
  'desktop': Size(1440, 900),
};

void main() {
  group('Responsive.scaleFor', () {
    test('is 1.0 on the reference phone', () {
      expect(Responsive.scaleFor(const Size(390, 844)), 1.0);
    });

    test('is clamped on tablets/desktop and small phones', () {
      expect(Responsive.scaleFor(const Size(1440, 900)), Responsive.maxScale);
      expect(Responsive.scaleFor(const Size(300, 600)), Responsive.minScale);
    });

    test('does not shrink a phone in landscape', () {
      expect(
        Responsive.scaleFor(const Size(844, 390)),
        Responsive.scaleFor(const Size(390, 844)),
      );
    });
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies(httpAdapter: fakeDummyJson());
  });

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProductManagerApp());
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: name, value: size) in _screens.entries) {
    testWidgets('login page lays out without overflow on $name', (
      tester,
    ) async {
      await pumpAt(tester, size);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dashboard and detail lay out without overflow on $name', (
      tester,
    ) async {
      await getIt<UserRepository>().create(
        name: 'Alexandra Montgomery-Smith',
        email: 'alexandra.montgomery@example.com',
        password: 'secret1',
      );
      await getIt<AuthRepository>().login(
        email: 'alexandra.montgomery@example.com',
        password: 'secret1',
      );

      await pumpAt(tester, size);
      expect(find.text('Phone X'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Phone X'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Phone X description'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Phone X description'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Users').last);
      await tester.pumpAndSettle();
      expect(find.text('Alexandra Montgomery-Smith'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
