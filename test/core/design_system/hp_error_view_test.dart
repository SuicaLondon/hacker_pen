import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/design_system/design_system.dart';

void main() {
  testWidgets('items error view retries', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: HpTheme.light(),
        home: HpErrorView(
          title: 'Failed to load items',
          retryLabel: 'Try again',
          message: 'offline',
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('Failed to load items'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('detail error view retries', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: HpTheme.light(),
        home: HpErrorView(
          title: 'Failed to load detail',
          message: 'missing',
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('Failed to load detail'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });
}
