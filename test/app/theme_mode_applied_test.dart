import 'package:checkplan/app/app.dart';
import 'package:checkplan/features/settings/application/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/memory_db.dart';
import '../support/test_overrides.dart';

void main() {
  testWidgets('CheckPlanApp applies the persisted theme mode', (tester) async {
    final db = memoryDb();
    await db.settingsDao.setValue(themeModeKey, themeModeName(ThemeMode.dark));

    await tester.pumpWidget(
      ProviderScope(
        // baseTestOverrides pins appDatabaseProvider to `db` and
        // currentDayProvider to a fixed day, so no midnight Timer is armed.
        overrides: baseTestOverrides(db: db),
        child: const CheckPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets(
    'seeds the first frame from initialThemeMode, then follows the store',
    (tester) async {
      // Empty store → the persisted stream resolves to system; the seed
      // differs, so the first frame proves the seed governs before the stream
      // emits (the cold-start flash fix — main() resolves it before runApp).
      await tester.pumpWidget(
        ProviderScope(
          overrides: baseTestOverrides(),
          child: const CheckPlanApp(initialThemeMode: ThemeMode.dark),
        ),
      );

      final firstFrame = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(firstFrame.themeMode, ThemeMode.dark);

      await tester.pumpAndSettle();

      // Once the persisted stream emits, the store governs (empty → system).
      final settled = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(settled.themeMode, ThemeMode.system);
    },
  );
}
