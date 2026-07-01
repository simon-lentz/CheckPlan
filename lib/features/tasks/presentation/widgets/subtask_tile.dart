import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/widgets/labeled_checkbox.dart';
import 'package:checkplan/core/widgets/notes_preview.dart';
import 'package:flutter/material.dart';

/// A single subtask row: a done checkbox, the title, a one-line notes preview
/// when the subtask has notes, and a delete button.
///
/// A leaf widget that takes its data and callbacks as parameters.
class SubtaskTile extends StatelessWidget {
  /// Creates a subtask row from [subtask] and its callbacks.
  const SubtaskTile({
    required this.subtask,
    required this.onToggleDone,
    required this.onEdit,
    required this.onDelete,
    this.dragHandle,
    super.key,
  });

  /// The subtask row this tile shows.
  final Subtask subtask;

  /// Invoked with the new done-state when the checkbox is toggled.
  final ValueChanged<bool> onToggleDone;

  /// Invoked when the user taps the row to edit the subtask.
  final VoidCallback onEdit;

  /// Invoked when the user taps delete.
  final VoidCallback onDelete;

  /// An optional drag affordance rendered before the delete button — supplied
  /// by a reorderable parent (a [ReorderableDragStartListener]); null when the
  /// row is not reorderable.
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final notes = displayNotes(subtask.notes);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 32, right: 8),
      onTap: onEdit,
      isThreeLine: notes.isNotEmpty,
      leading: LabeledCheckbox(
        label: toggleDoneLabel(subtask.title),
        value: subtask.isDone,
        onChanged: onToggleDone,
      ),
      title: Text(subtask.title),
      // One-line preview when the subtask has notes (mirrors TaskTile); absent
      // otherwise, so a note-less row is unchanged.
      subtitle: notes.isEmpty ? null : NotesPreview(notes),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?dragHandle,
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Delete subtask',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
