/// The maximum length of a checklist or task title.
const int maxTitleLength = 200;

/// Validates a raw title from an editor: trims, then rejects empty or
/// over-length input.
///
/// Returns null when [raw] is valid, otherwise a human-readable reason.
String? titleError(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'Title cannot be empty';
  if (trimmed.length > maxTitleLength) {
    return 'Title must be $maxTitleLength characters or fewer';
  }
  return null;
}
