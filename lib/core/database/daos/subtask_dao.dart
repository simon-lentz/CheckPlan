import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/tables/subtasks.dart';
import 'package:drift/drift.dart';

part 'subtask_dao.g.dart';

/// Reads and writes subtasks, exposing a reactive per-task list.
@DriftAccessor(tables: [Subtasks])
class SubtaskDao extends DatabaseAccessor<AppDatabase> with _$SubtaskDaoMixin {
  /// Binds the DAO to its attached database.
  SubtaskDao(super.attachedDatabase);

  /// A task's subtasks ordered by position; re-emits on any change.
  Stream<List<Subtask>> watchForTask(int taskId) {
    return (select(subtasks)
          ..where((s) => s.taskId.equals(taskId))
          ..orderBy([(s) => OrderingTerm(expression: s.position)]))
        .watch();
  }

  /// Adds a subtask to the task at the next free position.
  ///
  /// Allocating the position and inserting run in one transaction, so they are
  /// atomic.
  Future<int> add(int taskId, String title) {
    return transaction(() async {
      final now = DateTime.timestamp();
      return into(subtasks).insert(
        SubtasksCompanion.insert(
          taskId: taskId,
          title: title,
          position: await _nextPosition(taskId),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
  }

  /// Sets the subtask's completion flag.
  Future<int> setDone(int id, {required bool isDone}) =>
      (update(subtasks)..where((s) => s.id.equals(id))).write(
        SubtasksCompanion(
          isDone: Value(isDone),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );

  /// Renames the subtask with the given id.
  Future<int> rename(int id, String title) =>
      (update(subtasks)..where((s) => s.id.equals(id))).write(
        SubtasksCompanion(
          title: Value(title),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );

  /// Hard-deletes the subtask.
  Future<int> deleteById(int id) =>
      (delete(subtasks)..where((s) => s.id.equals(id))).go();

  /// Rewrites positions within a task to match the given id order.
  Future<void> reorder(int taskId, List<int> orderedIds) {
    final now = DateTime.timestamp();
    return batch((b) {
      for (final (index, id) in orderedIds.indexed) {
        b.update(
          subtasks,
          SubtasksCompanion(position: Value(index), updatedAt: Value(now)),
          // Scope to the owning task: a stray foreign id can't be moved.
          where: (s) => s.id.equals(id) & s.taskId.equals(taskId),
        );
      }
    });
  }

  Future<int> _nextPosition(int taskId) async {
    final maxPosition = subtasks.position.max();
    final query = selectOnly(subtasks)
      ..addColumns([maxPosition])
      ..where(subtasks.taskId.equals(taskId));
    final row = await query.getSingleOrNull();
    return (row?.read(maxPosition) ?? -1) + 1;
  }
}
