import 'package:checkplan/app/router.dart';
import 'package:checkplan/app/theme.dart';
import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:checkplan/features/settings/application/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The root widget: a Material 3 app that owns and disposes its [GoRouter] and
/// follows the persisted theme mode.
class CheckPlanApp extends ConsumerStatefulWidget {
  /// Creates the root application widget.
  ///
  /// [initialThemeMode] seeds the first frame's theme — the value `main` reads
  /// from the settings store before `runApp`, so an explicit (non-system)
  /// persisted mode is honored immediately with no cold-start flash. It governs
  /// only until [themeModeProvider]'s stream emits, after which the store is
  /// the source of truth. Defaults to [ThemeMode.system] (the pre-persistence
  /// launch default).
  const CheckPlanApp({this.initialThemeMode = ThemeMode.system, super.key});

  /// The theme mode applied on the first frame, before the persisted stream
  /// emits. See the constructor.
  final ThemeMode initialThemeMode;

  @override
  ConsumerState<CheckPlanApp> createState() => _CheckPlanAppState();
}

class _CheckPlanAppState extends ConsumerState<CheckPlanApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A password-recovery deep link establishes a [PasswordRecovery] session;
    // route to the set-new-password screen so the user can finish the reset.
    // `go` (not `push`) so completing it and returning home leaves no dangling
    // recovery route behind.
    ref.listen(authStateProvider, (_, next) {
      if (next.value is PasswordRecovery) _router.go('/new-password');
    });
    // Until the persisted mode's stream first emits, use the startup seed that
    // main() resolved from the store before the first frame — so an explicit
    // mode shows immediately, with no flash. After the stream emits, the store
    // governs.
    final themeMode =
        ref.watch(themeModeProvider).value ?? widget.initialThemeMode;
    return MaterialApp.router(
      title: 'CheckPlan',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
