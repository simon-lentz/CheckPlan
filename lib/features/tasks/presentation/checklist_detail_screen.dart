import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/tasks/application/task_providers.dart';
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
        AsyncData(:final value) => _TaskList(tasks: value),
        AsyncError(:final error) => _ErrorView(error: error),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// The non-empty list of task views.
class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks});

  final List<TaskView> tasks;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final view = tasks[index];
        return ListTile(
          key: ValueKey(view.task.id),
          title: Text(view.task.title),
        );
      },
    );
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
