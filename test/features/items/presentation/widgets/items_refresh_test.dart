import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/design_system/design_system.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/core/domain/story_type.dart';
import 'package:hacker_pen/src/features/items/data/items_repository.dart';
import 'package:hacker_pen/src/features/items/presentation/views/items_page.dart';

void main() {
  testWidgets('scroll hides the logo, keeps tabs, and reveals it on reversal', (
    tester,
  ) async {
    final repository = _RefreshRepository()
      ..items = List.generate(30, (index) => _story(index + 1));
    await _pumpFeed(tester, repository);
    final header = find.byType(HpCollapsibleHeader);
    final expandedHeight = tester.getSize(header).height;

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(tester.getSize(header).height, 0);
    expect(find.text('TOP').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Settings').hitTestable(), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 90));
    await tester.pumpAndSettle();
    expect(tester.getSize(header).height, expandedHeight);
    expect(find.byTooltip('Settings').hitTestable(), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ASK'));
    await tester.pumpAndSettle();
    expect(tester.getSize(header).height, expandedHeight);
    expect(find.text('story 1'), findsOneWidget);
  });

  testWidgets('pull keeps stories visible until refreshed content arrives', (
    tester,
  ) async {
    final repository = _RefreshRepository();
    await _pumpFeed(tester, repository);
    final initialStoryTop = tester.getTopLeft(find.text('story 1')).dy;
    final scrollable = tester.state<ScrollableState>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    final pending = repository.pending = Completer<List<HnItem>>();

    await _pullToRefresh(tester, find.text('story 1'));
    for (var frame = 0; frame < 90; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(repository.calls, 2);
    expect(find.text('story 1'), findsOneWidget);
    expect(find.byType(HpLoadingView), findsNothing);
    expect(
      tester.getTopLeft(find.text('story 1')).dy - initialStoryTop,
      closeTo(56, 1),
    );
    expect(
      tester.state<ScrollableState>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      ),
      scrollable,
    );

    pending.complete([_story(2)]);
    await tester.pumpAndSettle();

    expect(find.text('story 2'), findsOneWidget);
    expect(find.text('story 1'), findsNothing);
    expect(scrollable.position.pixels, closeTo(0, 0.1));
  });

  testWidgets('short pull moves the list and returns without refreshing', (
    tester,
  ) async {
    final repository = _RefreshRepository();
    await _pumpFeed(tester, repository);
    final start = tester.getTopLeft(find.text('story 1'));
    final headerStart = tester.getTopLeft(find.text('HACKERPEN'));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('story 1')),
    );
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 50));
    await tester.pump();

    expect(
      tester.getTopLeft(find.text('story 1')).dy,
      greaterThan(start.dy + 10),
    );
    expect(tester.getTopLeft(find.text('HACKERPEN')), headerStart);
    expect(repository.calls, 1);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('story 1')).dy, closeTo(start.dy, 0.1));
  });

  testWidgets('failed refresh keeps the feed readable and can be retried', (
    tester,
  ) async {
    final repository = _RefreshRepository();
    await _pumpFeed(tester, repository);
    final pending = repository.pending = Completer<List<HnItem>>();

    await _pullToRefresh(tester, find.text('story 1'));
    await tester.pump(const Duration(milliseconds: 500));
    pending.completeError(StateError('offline'));
    await tester.pumpAndSettle();

    expect(find.text('story 1'), findsOneWidget);
    expect(find.text('Failed to load items'), findsNothing);
    expect(
      find.text('Could not refresh. Pull down to try again.'),
      findsOneWidget,
    );

    repository.pending = null;
    repository.items = [_story(3)];
    await _pullToRefresh(tester, find.text('story 1'));
    await tester.pumpAndSettle();
    expect(find.text('story 3'), findsOneWidget);
  });

  testWidgets('empty feed still accepts pull to refresh', (tester) async {
    final repository = _RefreshRepository()..items = [];
    await _pumpFeed(tester, repository);
    repository.items = [_story(4)];

    await _pullToRefresh(tester, find.text('NO STORIES AVAILABLE'));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.text('story 4'), findsOneWidget);
  });
}

Future<void> _pullToRefresh(WidgetTester tester, Finder target) async {
  final gesture = await tester.startGesture(tester.getCenter(target));
  await gesture.moveBy(const Offset(0, 20));
  await tester.pump();
  await gesture.moveBy(const Offset(0, 400));
  await tester.pump(const Duration(milliseconds: 200));
  await gesture.up();
}

Future<void> _pumpFeed(
  WidgetTester tester,
  _RefreshRepository repository,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: HpTheme.dark(),
      home: RepositoryProvider<ItemsRepository>.value(
        value: repository,
        child: const ItemsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _RefreshRepository implements ItemsRepository {
  List<HnItem> items = [_story(1)];
  Completer<List<HnItem>>? pending;
  int calls = 0;

  @override
  Future<List<HnItem>> fetchItems({
    StoryType storyType = StoryType.top,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    calls++;
    return pending == null ? items : await pending!.future;
  }

  @override
  Future<List<HnItem>?> refreshVisibleItemsIfChanged({
    required StoryType storyType,
    required List<HnItem> currentItems,
    int limit = 20,
  }) async => null;
}

HnItem _story(int id) => HnItem(
  id: id,
  type: 'story',
  time: 1,
  by: 'author',
  title: 'story $id',
  score: 42,
  descendants: 5,
);
