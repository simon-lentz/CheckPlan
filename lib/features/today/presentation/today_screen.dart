import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/model/due_status.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/time/current_day.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/core/widgets/async_switcher.dart';
import 'package:checkplan/core/widgets/empty_view.dart';
import 'package:checkplan/core/widgets/error_snackbar.dart';
import 'package:checkplan/core/widgets/labeled_checkbox.dart';
import 'package:checkplan/features/tasks/application/subtask_providers.dart';
import 'package:checkplan/features/tasks/presentation/task_actions.dart';
import 'package:checkplan/features/today/application/today_providers.dart';
import 'package:checkplan/features/today/presentation/widgets/today_task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "Today" screen: a live list of incomplete tasks due today or overdue,
/// grouped into Overdue and Today sections.
class TodayScreen extends ConsumerWidget {
  /// Creates the Today screen.
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayProvider);
    final today = ref.watch(currentDayProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: AsyncSwitcher(
        value: todayAsync,
        isEmpty: (buckets) =>
            buckets.overdue.isEmpty && buckets.dueToday.isEmpty,
        empty: const EmptyView(
          message: 'Nothing due — nice.',
          icon: Icons.event_available,
        ),
        data: (buckets) => _TodayList(buckets: buckets, today: today),
      ),
    );
  }
}

/// The non-empty Today list: an Overdue section, then a Today section.
class _TodayList extends StatelessWidget {
  const _TodayList({required this.buckets, required this.today});

  final TodayBuckets buckets;
  final EpochDay today;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (buckets.overdue.isNotEmpty) const _SectionHeader('Overdue'),
        for (final entry in buckets.overdue)
          _TodayItem(
            key: ValueKey(entry.task.id),
            entry: entry,
            status: dueStatusFor(entry.task.dueDay, today),
          ),
        if (buckets.dueToday.isNotEmpty) const _SectionHeader('Today'),
        // No per-row chip under "Today": the section header already says these
        // are due today, so the chip would only repeat it.
        for (final entry in buckets.dueToday)
          _TodayItem(key: ValueKey(entry.task.id), entry: entry),
      ],
    );
  }
}

/// One Today row: the task tile plus, when expanded, its subtasks. Expansion is
/// local view state (mirrors the checklist-detail task row). A
/// `ConsumerStatefulWidget` so a subtask emission rebuilds only this row.
class _TodayItem extends ConsumerStatefulWidget {
  const _TodayItem({required this.entry, this.status, super.key});

  final TodayTask entry;
  final DueStatus? status;

  @override
  ConsumerState<_TodayItem> createState() => _TodayItemState();
}

class _TodayItemState extends ConsumerState<_TodayItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final hasSubtasks = entry.subtaskProgress.$2 > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TodayTaskTile(
          entry: entry,
          status: widget.status,
          expanded: _expanded,
          onToggleExpanded: () => setState(() => _expanded = !_expanded),
          onComplete: () =>
              toggleTaskDone(context, ref, entry.task.id, isDone: true),
        ),
        if (hasSubtasks)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _TodaySubtaskSection(taskId: entry.task.id)
                : const SizedBox(width: double.infinity),
          ),
      ],
    );
  }
}

/// The expanded Today row's subtasks: a read + **toggle-only** list (no add,
/// rename, reorder, or delete — those live on Checklist detail). Toggling the
/// last open subtask completes the parent, which drops the task from the Today
/// stream and unmounts this section.
class _TodaySubtaskSection extends ConsumerWidget {
  const _TodaySubtaskSection({required this.taskId});

  final int taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subtasksForTaskProvider(taskId));
    // Loading/error collapse to empty: the screen-level AsyncSwitcher already
    // guards the destructive read error, and the brief first-expand loading
    // frame is hidden by the enclosing AnimatedSize.
    final subtasks = switch (async) {
      AsyncData(:final value) => value,
      _ => const <Subtask>[],
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final subtask in subtasks)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            leading: LabeledCheckbox(
              label: toggleDoneLabel(subtask.title),
              value: subtask.isDone,
              onChanged: (isDone) =>
                  _toggle(context, ref, subtask.id, isDone: isDone),
            ),
            title: Text(subtask.title),
          ),
      ],
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    int id, {
    required bool isDone,
  }) async {
    final result = await ref
        .read(subtaskControllerProvider.notifier)
        .setDone(id, isDone: isDone);
    if (!context.mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not update the subtask');
    }
  }
}

/// A section label above a group of Today rows.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(label, style: Theme.of(context).textTheme.titleSmall),
  );
}
