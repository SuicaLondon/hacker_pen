import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/design_system/design_system.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/features/items/presentation/widgets/item_story_row.dart';

void main() {
  testWidgets('renders dense Hacker News story metadata on narrow screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: HpTheme.light(),
        home: Scaffold(
          body: ItemStoryRow(
            rank: 7,
            item: const HnItem(
              id: 1,
              type: 'story',
              time: 1,
              by: 'pg',
              title: 'A compact interface for reading dense technical news',
              score: 128,
              descendants: 42,
              url: 'https://news.ycombinator.com/item?id=1',
            ),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('07'), findsOneWidget);
    expect(find.textContaining('128 PTS · 42 COMMENTS ·'), findsOneWidget);
    expect(find.textContaining('news.ycombinator.com'), findsNothing);
    expect(find.byIcon(Icons.mode_comment_outlined), findsNothing);

    await tester.tap(find.byType(ItemStoryRow));
    expect(tapped, isTrue);
  });
}
