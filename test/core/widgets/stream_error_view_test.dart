import 'package:checkplan/core/widgets/stream_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the headline and no button without onRetry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StreamErrorView(error: Exception('boom'))),
      ),
    );
    expect(find.textContaining('Something went wrong'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsNothing);
  });

  testWidgets('shows a Retry button that fires onRetry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StreamErrorView(
            error: Exception('boom'),
            onRetry: () => retried++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });
}
