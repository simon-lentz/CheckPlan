import 'dart:async';

import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:checkplan/features/account/presentation/account_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/fake_auth_service.dart';
import '../../../support/pump_account_section.dart';

void main() {
  testWidgets('signed out: shows the not-backed-up message + Sign in', (
    tester,
  ) async {
    await pumpAccountSection(tester);
    expect(find.textContaining('Not backed up'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('does not flash the signed-out tiles during the first load', (
    tester,
  ) async {
    // A stream that never emits keeps authStateProvider in AsyncLoading, so the
    // section renders its initial (value-less) frame — the one a signed-in user
    // would briefly see. It must not default to the signed-out tiles.
    final controller = StreamController<AuthSnapshot>();
    addTearDown(controller.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authStateProvider.overrideWith((ref) => controller.stream)],
        child: const MaterialApp(home: Scaffold(body: AccountSection())),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Not backed up'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsNothing);
  });

  testWidgets('signed in: shows the email + Sign out', (tester) async {
    await pumpAccountSection(
      tester,
      fake: FakeAuthService(initial: const SignedIn('a@b.com')),
    );
    expect(find.text('a@b.com'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Sign out'), findsOneWidget);
  });

  testWidgets('Sign out calls the controller and returns to signed-out', (
    tester,
  ) async {
    final fake = FakeAuthService(initial: const SignedIn('a@b.com'));
    await pumpAccountSection(tester, fake: fake);
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(fake.calls, contains('signOut'));
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });
}
