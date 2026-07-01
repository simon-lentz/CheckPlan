import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/validation.dart';
import 'package:checkplan/core/widgets/form_error_text.dart';
import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Completes a password reset: the recovery deep link opens the app with a
/// [PasswordRecovery] session, the router lands here, and the user picks a new
/// password (entered twice to guard against a typo). On success the session
/// becomes a normal sign-in.
class NewPasswordScreen extends ConsumerStatefulWidget {
  /// Creates the set-new-password screen.
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  var _busy = false;
  var _done = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Set a new password')),
    body: _done ? _doneView(context) : _formView(context),
  );

  Widget _doneView(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Icon(Icons.lock_reset, size: 48),
      const SizedBox(height: 12),
      const Text(
        'Your password has been updated. You are now signed in.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () => context.go('/'),
        child: const Text('Continue'),
      ),
    ],
  );

  Widget _formView(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text('Choose a new password for your account.'),
      const SizedBox(height: 8),
      TextField(
        key: const Key('password'),
        controller: _password,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'New password'),
      ),
      TextField(
        key: const Key('confirmPassword'),
        controller: _confirm,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Confirm password'),
      ),
      FormErrorText(_error),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: const Text('Set password'),
      ),
    ],
  );

  Future<void> _submit() async {
    final invalid = passwordPairError(_password.text, _confirm.text);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(authControllerProvider.notifier)
        .updatePassword(_password.text);
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() {
          _busy = false;
          _done = true;
        });
      case Err(:final error):
        setState(() {
          _busy = false;
          _error = authFailureMessage(error, 'Could not update the password');
        });
    }
  }
}
