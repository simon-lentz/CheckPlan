import 'package:checkplan/core/result.dart';

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

/// The shortest password the account flows accept.
///
/// Matches Supabase's default minimum so a too-short password is rejected
/// client-side (with immediate feedback) rather than by a rejected network
/// round-trip. Keep this at or below the server's configured minimum — a higher
/// client floor would reject passwords the server would accept.
const int minPasswordLength = 6;

/// Validates a new password and its confirmation for the set-password flows
/// (sign-up and password-reset completion).
///
/// Returns null when [password] is at least [minPasswordLength] characters and
/// [confirmation] matches it exactly; otherwise a human-readable reason.
/// Requiring the confirmation guards against a typo in a field the user cannot
/// read back — so setting a password is never a one-shot action. Passwords are
/// compared verbatim (no trimming): whitespace is a legitimate password
/// character, so an exact match is the only match.
String? passwordPairError(String password, String confirmation) {
  if (password.length < minPasswordLength) {
    return 'Password must be at least $minPasswordLength characters';
  }
  if (password != confirmation) return 'Passwords do not match';
  return null;
}

/// Thrown across the write boundary when a title fails [titleError].
///
/// Carries the human-readable [message] from [titleError] so a controller can
/// reject invalid input as an `Err` before the database is touched, instead of
/// leaning on the DB length constraint as control flow.
class ValidationException implements Exception {
  /// Creates a validation failure carrying a human-readable [message].
  const ValidationException(this.message);

  /// The human-readable reason the input was rejected (from [titleError]).
  final String message;
}

/// Runs a title-validated write: validates [title] with [titleError] and, on
/// failure, returns an [Err] wrapping a [ValidationException] without running
/// [action]. Otherwise runs [action] with the trimmed title under
/// [Result.guard] — a caught exception becomes an [Err]; a programming `Error`
/// propagates. Shared by every controller's create/rename/add/edit command so
/// the validate-then-guard contract lives in one place.
Future<Result<T>> guardTitle<T>(
  String title,
  Future<T> Function(String title) action,
) {
  final error = titleError(title);
  if (error != null) return Future.value(Err(ValidationException(error)));
  return Result.guard(() => action(title.trim()));
}
