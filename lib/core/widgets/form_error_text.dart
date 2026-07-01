import 'package:flutter/material.dart';

/// Inline form-error text shown below a field.
///
/// Renders [message] in the theme's error color, or nothing when it is null —
/// so a form can place `const FormErrorText(_error)` unconditionally and let
/// the widget decide whether anything shows. Shared by the account screens so
/// inline error presentation lives in one place.
class FormErrorText extends StatelessWidget {
  /// Shows [message] as an inline error, or nothing when it is null.
  const FormErrorText(this.message, {super.key});

  /// The error to show, or null for no error.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
