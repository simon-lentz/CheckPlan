import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/validation.dart';
import 'package:checkplan/core/widgets/error_snackbar.dart';
import 'package:checkplan/core/widgets/form_error_text.dart';
import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Create-account form.
///
/// On success, email confirmation is pending (no session yet), so it shows a
/// "check your email" state with resend rather than signing in. The password is
/// entered twice and the two must match before submission, so a typo in a field
/// the user cannot read back never sets the account password.
class SignUpScreen extends ConsumerStatefulWidget {
  /// Creates the sign-up screen.
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  var _busy = false;
  var _pending = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create account')),
    body: _pending ? _pendingView() : _formView(context),
  );

  Widget _pendingView() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Icon(Icons.mark_email_unread_outlined, size: 48),
      const SizedBox(height: 12),
      Text(
        'Check your email to confirm ${_email.text.trim()}, then sign in.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: _busy ? null : _resend,
        child: const Text('Resend confirmation email'),
      ),
    ],
  );

  Widget _formView(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      TextField(
        key: const Key('email'),
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email'),
      ),
      TextField(
        key: const Key('password'),
        controller: _password,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Password'),
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
        child: const Text('Create account'),
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
        .signUp(_email.text.trim(), _password.text);
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() {
          _busy = false;
          _pending = true;
        });
      case Err(:final error):
        setState(() {
          _busy = false;
          _error = authFailureMessage(error, 'Could not create the account');
        });
    }
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .resendConfirmation(_email.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        showSnackBar(context, 'Confirmation email sent.');
      case Err(:final error):
        showErrorSnackBar(
          context,
          authFailureMessage(error, 'Could not resend the email'),
        );
    }
  }
}
