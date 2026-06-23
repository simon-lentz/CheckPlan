import 'package:checkplan/core/database/app_database.dart';

/// A `(done, total)` count pair.
typedef Progress = (int done, int total);

/// A checklist plus its task-completion progress from an aggregate query.
class ChecklistSummary {
  /// Pairs a checklist row with its computed task progress.
  const ChecklistSummary({required this.checklist, required this.progress});

  /// The checklist row this summary describes.
  final Checklist checklist;

  /// Tasks done out of total for the checklist.
  final Progress progress;
}
