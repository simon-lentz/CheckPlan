import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The error state for a stream-backed screen: a centered icon and a friendly
/// headline, with an optional Retry button that re-attempts the read.
///
/// The raw [error] text is shown only in debug builds as a diagnostic aid;
/// release builds show just the headline, never an exception's message.
class StreamErrorView extends StatelessWidget {
  /// Creates an error view for [error], optionally with an [onRetry] action.
  const StreamErrorView({required this.error, this.onRetry, super.key});

  /// The error emitted by the stream read.
  final Object error;

  /// Invoked when the user taps Retry, or null to omit the button.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (onRetry case final onRetry?) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
