import 'package:checkplan/app/app.dart';
import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:checkplan/features/account/presentation/new_password_screen.dart';
import 'package:checkplan/features/account/presentation/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_auth_service.dart';
import '../support/test_overrides.dart';

void main() {
  testWidgets('the Settings account section opens the sign-in screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        // baseTestOverrides pins appDatabaseProvider + currentDayProvider;
        // authServiceProvider defaults to SignedOutAuthService (no override
        // needed), so the account section renders its signed-out arm.
        overrides: baseTestOverrides(),
        child: const CheckPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('a password-recovery session opens the new-password screen', (
    tester,
  ) async {
    final fake = FakeAuthService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...baseTestOverrides(),
          authServiceProvider.overrideWithValue(fake),
        ],
        child: const CheckPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The recovery deep link establishes a recovery session; the app must route
    // to the set-new-password screen so the reset can be completed.
    fake.emit(const PasswordRecovery());
    await tester.pumpAndSettle();

    expect(find.byType(NewPasswordScreen), findsOneWidget);
  });
}
