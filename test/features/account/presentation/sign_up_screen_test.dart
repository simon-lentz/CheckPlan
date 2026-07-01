import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:checkplan/features/account/presentation/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/fake_auth_service.dart';
import '../../../support/pump_auth_screen.dart';

/// Enters a matching email + password pair and taps Create account.
Future<void> _createAccount(
  WidgetTester tester, {
  String email = 'a@b.com',
  String password = 'pw12345',
  String? confirm,
}) async {
  await tester.enterText(find.byKey(const Key('email')), email);
  await tester.enterText(find.byKey(const Key('password')), password);
  await tester.enterText(
    find.byKey(const Key('confirmPassword')),
    confirm ?? password,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('submitting reveals the check-your-email state', (tester) async {
    final fake = FakeAuthService();
    await pumpAuthScreen(tester, const SignUpScreen(), fake: fake);
    await _createAccount(tester);
    expect(fake.calls, contains('signUp:a@b.com'));
    expect(find.textContaining('Check your email'), findsOneWidget);
  });

  testWidgets('a failed sign-up shows the message inline', (tester) async {
    final fake = FakeAuthService()
      ..signUpError = const AuthFailure('Email already registered');
    await pumpAuthScreen(tester, const SignUpScreen(), fake: fake);
    await _createAccount(tester);
    expect(find.text('Email already registered'), findsOneWidget);
  });

  testWidgets('mismatched passwords block sign-up before any network call', (
    tester,
  ) async {
    final fake = FakeAuthService();
    await pumpAuthScreen(tester, const SignUpScreen(), fake: fake);
    await _createAccount(tester, confirm: 'pw12346');
    expect(fake.calls, isEmpty);
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('a successful resend confirms it', (tester) async {
    final fake = FakeAuthService();
    await pumpAuthScreen(tester, const SignUpScreen(), fake: fake);
    await _createAccount(tester);
    await tester.tap(
      find.widgetWithText(TextButton, 'Resend confirmation email'),
    );
    await tester.pumpAndSettle();
    expect(fake.calls, contains('resend:a@b.com'));
    expect(find.text('Confirmation email sent.'), findsOneWidget);
  });

  testWidgets('a failed resend surfaces the error', (tester) async {
    final fake = FakeAuthService()
      ..resendError = const AuthFailure('Too many requests');
    await pumpAuthScreen(tester, const SignUpScreen(), fake: fake);
    await _createAccount(tester);
    await tester.tap(
      find.widgetWithText(TextButton, 'Resend confirmation email'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Too many requests'), findsOneWidget);
  });
}
