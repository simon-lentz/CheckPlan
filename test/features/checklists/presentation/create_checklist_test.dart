import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/features/checklists/presentation/checklists_screen.dart';
// Import drift with `isNull` hidden to avoid static conflicts (flutter_test).
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase memoryDb() => AppDatabase(
  DatabaseConnection(
    NativeDatabase.memory(),
    closeStreamsSynchronously: true,
  ),
);

void main() {
  testWidgets('FAB opens the dialog and creates a checklist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(memoryDb())],
        child: const MaterialApp(home: ChecklistsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Groceries');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsOneWidget);
  });

  testWidgets('Add is disabled until the title is non-empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(memoryDb())],
        child: const MaterialApp(home: ChecklistsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    final addButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Add'),
    );
    expect(addButton.onPressed, isNull); // disabled while empty
  });
}
