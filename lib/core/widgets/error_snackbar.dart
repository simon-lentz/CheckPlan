import 'package:flutter/material.dart';

/// Shows a transient [message] over the nearest [Scaffold].
void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Shows a transient error [message] over the nearest [Scaffold].
///
/// A thin alias for [showSnackBar] that names the intent at the call site (and
/// a seam for error-specific styling later).
void showErrorSnackBar(BuildContext context, String message) =>
    showSnackBar(context, message);
