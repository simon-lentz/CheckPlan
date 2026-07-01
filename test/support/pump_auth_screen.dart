import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fake_auth_service.dart';

/// Pumps an auth [screen] with `authServiceProvider` overridden by [fake] (or a
/// fresh signed-out fake) in a plain `MaterialApp`, then settles.
///
/// The auth screens drive writes through `authControllerProvider` and never
/// watch `authStateProvider`, so a plain `MaterialApp` suffices. The exception
/// is `SignInScreen`, whose success path pops its route — that needs a
/// router-based pump with a return target, so it keeps its own helper.
Future<void> pumpAuthScreen(
  WidgetTester tester,
  Widget screen, {
  FakeAuthService? fake,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(fake ?? FakeAuthService()),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}
