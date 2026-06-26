import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/features/tasks/presentation/checklist_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_overrides.dart';

/// Pumps [ChecklistDetailScreen] for [checklistId] inside a `ProviderScope` +
/// `MaterialApp`, then settles.
///
/// Backs it with a fresh in-memory database unless [db] is supplied (pass a
/// pre-seeded database to render existing tasks) and pins `currentDayProvider`
/// to [today] (a default when omitted) via [baseTestOverrides]. Extra
/// [overrides] layer on top.
Future<void> pumpChecklistDetailScreen(
  WidgetTester tester, {
  required int checklistId,
  AppDatabase? db,
  EpochDay? today,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...baseTestOverrides(db: db, today: today),
        ...overrides,
      ],
      child: MaterialApp(home: ChecklistDetailScreen(checklistId: checklistId)),
    ),
  );
  await tester.pumpAndSettle();
}
