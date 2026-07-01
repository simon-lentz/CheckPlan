import 'package:checkplan/core/widgets/form_error_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the message when non-null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FormErrorText('Bad input'))),
    );
    expect(find.text('Bad input'), findsOneWidget);
  });

  testWidgets('renders nothing when null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FormErrorText(null))),
    );
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('styles the message with the theme error color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FormErrorText('Bad'))),
    );
    final context = tester.element(find.text('Bad'));
    final text = tester.widget<Text>(find.text('Bad'));
    expect(text.style?.color, Theme.of(context).colorScheme.error);
  });
}
