import 'package:checkplan/core/database/daos/task_dao.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Accessor for the [TaskDao], backed by the shared database.
final taskDaoProvider = Provider<TaskDao>(
  (ref) => ref.watch(appDatabaseProvider).taskDao,
);

/// Reactive list of a checklist's tasks, each with its subtask progress.
///
/// Keyed by checklist id and `autoDispose` so a closed detail screen's stream
/// is torn down. Re-emits whenever the checklist's tasks or their subtasks
/// change.
final StreamProviderFamily<List<TaskView>, int> tasksForChecklistProvider =
    StreamProvider.autoDispose.family<List<TaskView>, int>(
      (ref, checklistId) =>
          ref.watch(taskDaoProvider).watchForChecklist(checklistId),
    );
