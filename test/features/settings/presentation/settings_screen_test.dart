import 'dart:async';

import 'package:checkplan/core/result.dart';
import 'package:checkplan/features/settings/application/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/pump_settings_screen.dart';

/// A controller whose `setThemeMode` fails, to drive the error feedback.
class _FailingSettingsController extends SettingsController {
  @override
  Future<Result<void>> setThemeMode(ThemeMode mode) async =>
      Err(Exception('boom'));
}

/// A controller whose `setThemeMode` never completes, so the persisted stream
/// never catches up — isolating the screen's own optimistic selection.
class _BlockingSettingsController extends SettingsController {
  final _never = Completer<Result<void>>();

  @override
  Future<Result<void>> setThemeMode(ThemeMode mode) => _never.future;
}

Set<ThemeMode> _selectedMode(WidgetTester tester) => tester
    .widget<SegmentedButton<ThemeMode>>(find.byType(SegmentedButton<ThemeMode>))
    .selected;

void main() {
  testWidgets('shows the three theme options', (tester) async {
    await pumpSettingsScreen(tester);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('selecting Dark persists it', (tester) async {
    await pumpSettingsScreen(tester);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(_selectedMode(tester), {ThemeMode.dark});
  });

  testWidgets('highlights the tapped segment before the write round-trips', (
    tester,
  ) async {
    // The write never completes, so the persisted stream can never re-emit —
    // any movement of the highlight must come from the screen's own optimistic
    // state, not the store.
    await pumpSettingsScreen(
      tester,
      overrides: [
        settingsControllerProvider.overrideWith(
          _BlockingSettingsController.new,
        ),
      ],
    );
    expect(_selectedMode(tester), {ThemeMode.system});

    await tester.tap(find.text('Dark'));
    await tester.pump();

    expect(_selectedMode(tester), {ThemeMode.dark});
  });

  testWidgets('reverts the optimistic highlight when the write fails', (
    tester,
  ) async {
    await pumpSettingsScreen(
      tester,
      overrides: [
        settingsControllerProvider.overrideWith(_FailingSettingsController.new),
      ],
    );
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    // The failed write rolls the selection back to the persisted value.
    expect(_selectedMode(tester), {ThemeMode.system});
  });

  testWidgets('a write failure shows an error', (tester) async {
    await pumpSettingsScreen(
      tester,
      overrides: [
        settingsControllerProvider.overrideWith(_FailingSettingsController.new),
      ],
    );
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(find.text('Could not update the theme'), findsOneWidget);
  });
}
