import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/widgets/error_snackbar.dart';
import 'package:checkplan/core/widgets/name_dialog.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/tasks/application/task_providers.dart';
import 'package:checkplan/features/tasks/presentation/widgets/task_editor_sheet.dart';
import 'package:checkplan/features/tasks/presentation/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A checklist's detail screen: a live, reactive list of its tasks.
class ChecklistDetailScreen extends ConsumerWidget {
  /// Creates the detail screen for the checklist with [checklistId].
  const ChecklistDetailScreen({required this.checklistId, super.key});

  /// The id of the checklist whose tasks are shown.
  final int checklistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title =
        ref.watch(checklistByIdProvider(checklistId))?.checklist.title ??
        'Checklist';
    final tasksAsync = ref.watch(tasksForChecklistProvider(checklistId));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: switch (tasksAsync) {
        AsyncData(:final value) when value.isEmpty => const _EmptyTasks(),
        AsyncData(:final value) => _TaskList(
          tasks: value,
          checklistId: checklistId,
        ),
        AsyncError(:final error) => _ErrorView(error: error),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: switch (tasksAsync) {
        AsyncData() => FloatingActionButton(
          onPressed: () => _addTask(context, ref, checklistId),
          child: const Icon(Icons.add),
        ),
        _ => null,
      },
    );
  }
}

Future<void> _addTask(
  BuildContext context,
  WidgetRef ref,
  int checklistId,
) async {
  final title = await showNameDialog(
    context,
    title: 'New task',
    submitLabel: 'Add',
  );
  if (title == null) return;
  final result = await ref
      .read(taskControllerProvider.notifier)
      .add(checklistId, title);
  if (!context.mounted) return;
  if (result case Err()) showErrorSnackBar(context, 'Could not add the task');
}

/// The non-empty list of task views.
class _TaskList extends ConsumerWidget {
  const _TaskList({required this.tasks, required this.checklistId});

  final List<TaskView> tasks;
  final int checklistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
      itemCount: tasks.length,
      onReorderItem: (oldIndex, newIndex) =>
          _reorder(context, ref, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final view = tasks[index];
        return Dismissible(
          key: ValueKey('dismiss-${view.task.id}'),
          direction: DismissDirection.endToStart,
          background: const ColoredBox(
            color: Colors.red,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.delete, color: Colors.white),
              ),
            ),
          ),
          // Delete inside confirmDismiss and return false so the Dismissible
          // never enters its dismissed state. On success the reactive stream
          // removes the row; on failure it stays, with a snackbar. Returning
          // true while the async delete and its re-emit are in flight would
          // assert that a dismissed Dismissible is still in the tree.
          confirmDismiss: (_) =>
              _confirmAndDelete(context, ref, view.task.id, view.task.title),
          child: TaskTile(
            onEdit: () => _edit(context, ref, view),
            key: ValueKey(view.task.id),
            view: view,
            onToggleDone: (isDone) =>
                _toggle(context, ref, view.task.id, isDone: isDone),
          ),
        );
      },
    );
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    int oldIndex,
    int newIndex,
  ) async {
    // onReorderItem already adjusts newIndex for the item removed at oldIndex.
    final ids = tasks.map((t) => t.task.id).toList();
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    final result = await ref
        .read(taskControllerProvider.notifier)
        .reorder(checklistId, ids);
    if (!context.mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not reorder the tasks');
    }
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$title"?'),
        content: const Text(
          'This also deletes its subtasks. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  // Confirms, then deletes, then always returns false: on success the reactive
  // stream removes the row (so the Dismissible never enters its dismissed state
  // mid-async-write); on failure the row stays and a snackbar shows.
  Future<bool> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    int id,
    String title,
  ) async {
    final confirmed = await _confirmDelete(context, title);
    if (!confirmed || !context.mounted) return false;
    final result = await ref.read(taskControllerProvider.notifier).delete(id);
    if (!context.mounted) return false;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not delete the task');
    }
    return false;
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    int id, {
    required bool isDone,
  }) async {
    final result = await ref
        .read(taskControllerProvider.notifier)
        .setDone(id, isDone: isDone);
    if (!context.mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not update the task');
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, TaskView view) async {
    final draft = await showTaskEditorSheet(context, task: view.task);
    if (draft == null || !context.mounted) return;
    final result = await ref
        .read(taskControllerProvider.notifier)
        .edit(view.task.id, title: draft.title, notes: draft.notes);
    if (!context.mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not save the task');
    }
  }
}

/// Shown when the checklist has no tasks.
class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No tasks yet'));
  }
}

/// Shown when the tasks stream emits an error.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Something went wrong:\n$error'));
  }
}
