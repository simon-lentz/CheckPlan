import 'package:flutter/material.dart';

/// A one-line, ellipsized preview of a task's notes — the shared notes line
/// rendered beneath the title in the checklist-detail and Today task tiles, so
/// the preview's presentation stays identical across both.
class NotesPreview extends StatelessWidget {
  /// Creates a one-line preview of the (already-trimmed, non-empty) [notes].
  const NotesPreview(this.notes, {super.key});

  /// The notes text to preview on a single line.
  final String notes;

  @override
  Widget build(BuildContext context) =>
      Text(notes, maxLines: 1, overflow: TextOverflow.ellipsis);
}
