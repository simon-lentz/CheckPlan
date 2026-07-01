import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:checkplan/features/account/presentation/new_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/fake_auth_service.dart';
import '../../../support/pump_auth_screen.dart';

void main() {
  testWidgets('a matching, long-enough password completes the reset', (
    tester,
  ) async {
    final fake = FakeAuthService();
    await pumpAuthScreen(tester, const NewPasswordScreen(), fake: fake);
    await tester.enterText(find.byKey(const Key('password')), 'newpass1');
    await tester.enterText(
      find.byKey(const Key('confirmPassword')),
      'newpass1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Set password'));
    await tester.pumpAndSettle();
    expect(fake.calls, contains('updatePassword'));
    expect(find.textContaining('password has been updated'), findsOneWidget);
  });

  testWidgets('mismatched passwords block the update', (tester) async {
    final fake = FakeAuthService();
    await pumpAuthScreen(tester, const NewPasswordScreen(), fake: fake);
    await tester.enterText(find.byKey(const Key('password')), 'newpass1');
    await tester.enterText(
      find.byKey(const Key('confirmPassword')),
      'newpass2',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Set password'));
    await tester.pumpAndSettle();
    expect(fake.calls, isNot(contains('updatePassword')));
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('a too-short password blocks the update', (tester) async {
    final fake = FakeAuthService();
    await pumpAuthScreen(tester, const NewPasswordScreen(), fake: fake);
    await tester.enterText(find.byKey(const Key('password')), 'short');
    await tester.enterText(find.byKey(const Key('confirmPassword')), 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Set password'));
    await tester.pumpAndSettle();
    expect(fake.calls, isNot(contains('updatePassword')));
    expect(find.textContaining('at least'), findsOneWidget);
  });

  testWidgets('a failed update shows the message inline', (tester) async {
    final fake = FakeAuthService()
      ..updatePasswordError = const AuthFailure('Session expired');
    await pumpAuthScreen(tester, const NewPasswordScreen(), fake: fake);
    await tester.enterText(find.byKey(const Key('password')), 'newpass1');
    await tester.enterText(
      find.byKey(const Key('confirmPassword')),
      'newpass1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Set password'));
    await tester.pumpAndSettle();
    expect(find.text('Session expired'), findsOneWidget);
  });
}
