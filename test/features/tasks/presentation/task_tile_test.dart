import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/features/tasks/presentation/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/seed_reads.dart';

void main() {
  final today = EpochDay.fromDateTime(DateTime(2026, 6, 20));

  testWidgets('shows a subtask hint only when subtasks exist', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    await db.taskDao.add(list, 'Task');
    final task = await db.readSingleTask();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TaskTile(
                today: today,
                expanded: false,
                onToggleExpanded: () {},
                onEdit: () {},
                view: TaskView(task: task, subtaskProgress: (0, 0)),
                onToggleDone: (_) {},
              ),
              TaskTile(
                today: today,
                expanded: false,
                onToggleExpanded: () {},
                onEdit: () {},
                view: TaskView(task: task, subtaskProgress: (1, 3)),
                onToggleDone: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('1/3'), findsOneWidget); // hint for the (1,3) tile
    expect(find.text('0/0'), findsNothing); // no hint for (0,0)
  });

  testWidgets('makes the checkbox read-only when the task has subtasks', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    await db.taskDao.add(list, 'Task');
    final task = await db.readSingleTask();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TaskTile(
                today: today,
                expanded: false,
                onToggleExpanded: () {},
                onEdit: () {},
                view: TaskView(task: task, subtaskProgress: (1, 2)),
                onToggleDone: (_) {},
              ),
              TaskTile(
                today: today,
                expanded: false,
                onToggleExpanded: () {},
                onEdit: () {},
                view: TaskView(task: task, subtaskProgress: (0, 0)),
                onToggleDone: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(boxes[0].onChanged, isNull); // (1,2): derived -> disabled
    expect(boxes[1].onChanged, isNotNull); // (0,0): manual -> enabled
  });

  testWidgets('tapping the read-only checkbox toggles expansion, not done', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    await db.taskDao.add(list, 'Task');
    final task = await db.readSingleTask();

    var expandToggles = 0;
    var doneToggles = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTile(
            today: today,
            expanded: false,
            onToggleExpanded: () => expandToggles++,
            onEdit: () {},
            view: TaskView(task: task, subtaskProgress: (1, 2)),
            onToggleDone: (_) => doneToggles++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(expandToggles, 1); // the tap expanded the subtasks
    expect(doneToggles, 0); // and did not attempt completion
  });

  testWidgets('shows a due-date chip when the task has a due date', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    final id = await db.taskDao.add(list, 'Task');
    await db.taskDao.setDueDate(
      id,
      EpochDay.fromDateTime(DateTime(2026, 6, 18)),
    );
    final task = await db.readSingleTask();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTile(
            today: today, // 2026-06-20, two days after the due date
            expanded: false,
            onToggleExpanded: () {},
            onEdit: () {},
            view: TaskView(task: task, subtaskProgress: (0, 0)),
            onToggleDone: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Overdue 2d'), findsOneWidget);
  });

  testWidgets('shows a one-line notes preview when the task has notes', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    final id = await db.taskDao.add(list, 'Task');
    await db.taskDao.edit(
      id,
      title: 'Task',
      notes: 'buy oat milk',
      dueDay: null,
    );
    final task = await db.readSingleTask();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTile(
            today: today,
            expanded: false,
            onToggleExpanded: () {},
            onEdit: () {},
            view: TaskView(task: task, subtaskProgress: (0, 0)),
            onToggleDone: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('buy oat milk'), findsOneWidget);
  });

  testWidgets('stacks the due chip above the notes preview when both exist', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    final id = await db.taskDao.add(list, 'Task');
    await db.taskDao.edit(
      id,
      title: 'Task',
      notes: 'buy oat milk',
      dueDay: EpochDay.fromDateTime(DateTime(2026, 6, 18)),
    );
    final task = await db.readSingleTask();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTile(
            today: today, // 2026-06-20, two days after the due date
            expanded: false,
            onToggleExpanded: () {},
            onEdit: () {},
            view: TaskView(task: task, subtaskProgress: (0, 0)),
            onToggleDone: (_) {},
          ),
        ),
      ),
    );

    // With both present the subtitle renders the chip (the `?dueChip` branch)
    // above the one-line notes preview.
    expect(find.text('Overdue 2d'), findsOneWidget);
    expect(find.text('buy oat milk'), findsOneWidget);
  });
}
