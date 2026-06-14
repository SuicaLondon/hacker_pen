import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/design_system/design_system.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/widgets/item_detail_error_view.dart';
import 'package:hacker_pen/src/features/items/presentation/widgets/items_error_view.dart';

void main() {
  testWidgets('items error view retries', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: HpTheme.light(),
        home: ItemsErrorView(message: 'offline', onRetry: () => retried = true),
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
        home: ItemDetailErrorView(
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
