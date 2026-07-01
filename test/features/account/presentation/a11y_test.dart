import 'package:checkplan/features/account/presentation/new_password_screen.dart';
import 'package:checkplan/features/account/presentation/password_reset_screen.dart';
import 'package:checkplan/features/account/presentation/sign_in_screen.dart';
import 'package:checkplan/features/account/presentation/sign_up_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/a11y.dart';
import '../../../support/pump_auth_screen.dart';

void main() {
  testWidgets('Sign in meets tap-target and labelled-tappable guidelines', (
    tester,
  ) async {
    await pumpAuthScreen(tester, const SignInScreen());
    await expectMeetsTapTargetGuidelines(tester);
  });

  testWidgets('Sign up meets tap-target and labelled-tappable guidelines', (
    tester,
  ) async {
    await pumpAuthScreen(tester, const SignUpScreen());
    await expectMeetsTapTargetGuidelines(tester);
  });

  testWidgets('Reset password meets tap-target guidelines', (tester) async {
    await pumpAuthScreen(tester, const PasswordResetScreen());
    await expectMeetsTapTargetGuidelines(tester);
  });

  testWidgets('Set new password meets tap-target guidelines', (tester) async {
    await pumpAuthScreen(tester, const NewPasswordScreen());
    await expectMeetsTapTargetGuidelines(tester);
  });
}
