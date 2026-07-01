import 'package:checkplan/features/tasks/presentation/widgets/subtask_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';

void main() {
  testWidgets('edits title and notes and returns the draft', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    final taskId = await db.taskDao.add(list, 'T');
    await db.subtaskDao.add(taskId, 'Old');
    final subtask = (await db.select(db.subtasks).get()).single;

    SubtaskDraft? draft;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => draft = await showSubtaskEditorSheet(
                context,
                subtask: subtask,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'New');
    await tester.enterText(find.widgetWithText(TextField, 'Notes'), 'a note');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(draft?.title, 'New');
    expect(draft?.notes, 'a note');
  });
}
