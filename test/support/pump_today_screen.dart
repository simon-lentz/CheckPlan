import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/time/current_day.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/features/today/presentation/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'memory_db.dart';

/// Pumps [TodayScreen] inside a `ProviderScope` + `MaterialApp`, then settles.
///
/// Backs it with a fresh in-memory database from [memoryDb] unless [db] is
/// supplied (pass a pre-seeded database to render due tasks). [today] pins
/// `currentDayProvider` to a fixed day (a default when omitted) so the screen
/// never arms the real midnight `Timer`. Extra [overrides] layer on top.
Future<void> pumpTodayScreen(
  WidgetTester tester, {
  AppDatabase? db,
  EpochDay? today,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db ?? memoryDb()),
        currentDayProvider.overrideWithValue(
          today ?? EpochDay.fromDateTime(DateTime(2026)),
        ),
        ...overrides,
      ],
      child: const MaterialApp(home: TodayScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
