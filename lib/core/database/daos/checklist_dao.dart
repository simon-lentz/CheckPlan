import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/database/tables/checklists.dart';
import 'package:checkplan/core/database/tables/tasks.dart';
import 'package:drift/drift.dart';

part 'checklist_dao.g.dart';

/// Reads and writes checklists, exposing reactive task-progress summaries.
@DriftAccessor(tables: [Checklists, Tasks])
class ChecklistDao extends DatabaseAccessor<AppDatabase>
    with _$ChecklistDaoMixin {
  /// Binds the DAO to its attached database.
  ChecklistDao(super.attachedDatabase);

  /// Non-archived checklists ordered by `position`, each with its task
  /// `(done, total)` counts.
  ///
  /// Re-emits whenever checklists or tasks change.
  Stream<List<ChecklistSummary>> watchActiveSummaries() {
    final total = tasks.id.count();
    final done = tasks.id.count(filter: tasks.isDone.equals(true));
    final query =
        select(checklists).join([
            // useColumns: false. Read the counts, not the joined rows.
            leftOuterJoin(
              tasks,
              tasks.checklistId.equalsExp(checklists.id),
              useColumns: false,
            ),
          ])
          ..addColumns([total, done])
          ..where(checklists.archivedAt.isNull())
          ..groupBy([checklists.id])
          ..orderBy([OrderingTerm(expression: checklists.position)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => ChecklistSummary(
              checklist: row.readTable(checklists),
              progress: (row.read(done) ?? 0, row.read(total) ?? 0),
            ),
          )
          .toList(),
    );
  }

  /// Creates a checklist with the given title at the next free position.
  ///
  /// Allocating the position and inserting run in one transaction, so the
  /// `MAX(position)+1` read and the insert are atomic.
  Future<int> create(String title) {
    return transaction(() async {
      final now = DateTime.timestamp();
      return into(checklists).insert(
        ChecklistsCompanion.insert(
          title: title,
          position: await _nextPosition(),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
  }

  /// Renames the checklist with the given id.
  Future<int> rename(int id, String title) =>
      (update(checklists)..where((c) => c.id.equals(id))).write(
        ChecklistsCompanion(
          title: Value(title),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );

  /// Sets or clears the checklist's theme colour — an ARGB int, or null to
  /// restore the default.
  Future<int> setColor(int id, int? colorValue) =>
      (update(checklists)..where((c) => c.id.equals(id))).write(
        ChecklistsCompanion(
          colorValue: Value(colorValue),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );

  /// Archives the checklist, hiding it from the active list.
  Future<int> archive(int id) =>
      (update(checklists)..where((c) => c.id.equals(id))).write(
        ChecklistsCompanion(
          archivedAt: Value(DateTime.timestamp()),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );

  /// Restores a previously archived checklist.
  Future<int> restore(int id) =>
      (update(checklists)..where((c) => c.id.equals(id))).write(
        ChecklistsCompanion(
          archivedAt: const Value(null),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );

  /// Hard-deletes the checklist, cascading to its tasks.
  Future<int> deleteById(int id) =>
      (delete(checklists)..where((c) => c.id.equals(id))).go();

  /// Rewrites positions so they match the given id order, atomically.
  Future<void> reorder(List<int> orderedIds) {
    final now = DateTime.timestamp();
    return batch((b) {
      for (final (index, id) in orderedIds.indexed) {
        b.update(
          checklists,
          ChecklistsCompanion(position: Value(index), updatedAt: Value(now)),
          where: (c) => c.id.equals(id),
        );
      }
    });
  }

  Future<int> _nextPosition() async {
    final maxPosition = checklists.position.max();
    final query = selectOnly(checklists)..addColumns([maxPosition]);
    final row = await query.getSingleOrNull();
    return (row?.read(maxPosition) ?? -1) + 1;
  }
}
