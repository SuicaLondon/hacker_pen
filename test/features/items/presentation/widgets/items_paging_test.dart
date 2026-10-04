import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/design_system/design_system.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/core/domain/story_type.dart';
import 'package:hacker_pen/src/features/items/data/items_repository.dart';
import 'package:hacker_pen/src/features/items/presentation/cubit/items_cubit.dart';
import 'package:hacker_pen/src/features/items/presentation/views/items_page.dart';

void main() {
  testWidgets('swipes and tab taps stay synchronized, including the last tab', (
    tester,
  ) async {
    final repository = _PagingRepository();
    await _pumpFeed(tester, repository);
    expect(repository.calls, [StoryType.top]);
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(_selected(tester), 0);

    await _swipe(tester, -300);
    expect(_selected(tester), 1);
    expect(find.text('New 1').hitTestable(), findsOneWidget);
    expect(find.text('Top 1').hitTestable(), findsNothing);
    await _swipe(tester, 300);
    expect(_selected(tester), 0);
    expect(find.text('Top 1').hitTestable(), findsOneWidget);

    await tester.tap(find.text('ASK'));
    await tester.pumpAndSettle();
    expect(_selected(tester), 3);
    expect(find.text('Ask 1').hitTestable(), findsOneWidget);
    await _swipe(tester, -300);
    expect(_selected(tester), 4);
    expect(find.text('SHOW').hitTestable(), findsOneWidget);
    expect(find.text('Show 1').hitTestable(), findsOneWidget);
    await _swipe(tester, -300);
    expect(_selected(tester), 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pages follow the finger and a cancelled swipe keeps the selection',
    (tester) async {
      await _pumpFeed(tester, _PagingRepository());
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(-25, 0));
      await gesture.moveBy(const Offset(-70, 0));
      await tester.pump();
      final pager = tester.widget<PageView>(find.byType(PageView));
      expect(pager.controller!.page, greaterThan(0));
      expect(pager.controller!.page, lessThan(0.5));
      await gesture.moveBy(const Offset(95, 0));
      await tester.pump(const Duration(milliseconds: 150));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_selected(tester), 0);
      expect(find.text('Top 1').hitTestable(), findsOneWidget);
    },
  );

  testWidgets('each list retains its own scroll position without refetching', (
    tester,
  ) async {
    final repository = _PagingRepository();
    await _pumpFeed(tester, repository);
    await tester.drag(_feed(StoryType.top), const Offset(0, -350));
    await tester.pumpAndSettle();
    final topOffset = _position(tester, StoryType.top).pixels;
    expect(topOffset, greaterThan(200));
    expect(_selected(tester), 0);
    await _swipe(tester, -300);
    expect(_position(tester, StoryType.newStories).pixels, 0);
    await tester.drag(_feed(StoryType.newStories), const Offset(0, -200));
    await tester.pumpAndSettle();
    final newOffset = _position(tester, StoryType.newStories).pixels;
    await _swipe(tester, 300);
    expect(_position(tester, StoryType.top).pixels, closeTo(topOffset, 1));
    // Returning to a saved offset must not hide the logo on an upward drag.
    await tester.drag(_feed(StoryType.top), const Offset(0, 45));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Settings').hitTestable(), findsOneWidget);
    await _swipe(tester, -300);
    expect(
      _position(tester, StoryType.newStories).pixels,
      closeTo(newOffset, 1),
    );
    expect(
      repository.calls.where((type) => type == StoryType.top),
      hasLength(1),
    );
    expect(
      repository.calls.where((type) => type == StoryType.newStories),
      hasLength(1),
    );
  });

  testWidgets('late loads and refreshes stay with their original page', (
    tester,
  ) async {
    final repository = _PagingRepository();
    final initial = repository.pending[StoryType.top] =
        Completer<List<HnItem>>();
    await _pumpFeed(tester, repository, settle: false);
    await _swipe(tester, -300);
    expect(find.text('New 1').hitTestable(), findsOneWidget);
    initial.complete([_story(StoryType.top, 99)]);
    await tester.pumpAndSettle();
    expect(find.text('New 1').hitTestable(), findsOneWidget);
    await _swipe(tester, 300);
    expect(find.text('Top 99').hitTestable(), findsOneWidget);

    final pendingRefresh = repository.pending[StoryType.top] =
        Completer<List<HnItem>>();
    final refresh = tester
        .element(_feed(StoryType.top))
        .read<ItemsCubit>()
        .refreshItems();
    await _swipe(tester, -300);
    pendingRefresh.complete([_story(StoryType.top, 100)]);
    await refresh;
    await tester.pumpAndSettle();
    expect(find.text('New 1').hitTestable(), findsOneWidget);
    await _swipe(tester, 300);
    expect(find.text('Top 100').hitTestable(), findsOneWidget);
    expect(repository.forcedTypes, [StoryType.top]);
  });
}

Finder _feed(StoryType type) => find.byWidgetPredicate(
  (widget) => widget is CustomScrollView && widget.key == ValueKey(type),
);

ScrollPosition _position(WidgetTester tester, StoryType type) => tester
    .state<ScrollableState>(
      find.descendant(of: _feed(type), matching: find.byType(Scrollable)),
    )
    .position;

int _selected(WidgetTester tester) =>
    tester.widget<HpSegmentTabs>(find.byType(HpSegmentTabs)).selectedIndex;

Future<void> _swipe(WidgetTester tester, double delta) async {
  await tester.drag(find.byType(PageView), Offset(delta, 0));
  await tester.pumpAndSettle();
}

Future<void> _pumpFeed(
  WidgetTester tester,
  _PagingRepository repository, {
  bool settle = true,
}) async {
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
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

class _PagingRepository implements ItemsRepository {
  final calls = <StoryType>[];
  final forcedTypes = <StoryType>[];
  final pending = <StoryType, Completer<List<HnItem>>>{};

  @override
  Future<List<HnItem>> fetchItems({
    StoryType storyType = StoryType.top,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    calls.add(storyType);
    if (forceRefresh) forcedTypes.add(storyType);
    if (pending[storyType] case final response?) return response.future;
    return List.generate(30, (index) => _story(storyType, index + 1));
  }

  @override
  Future<List<HnItem>?> refreshVisibleItemsIfChanged({
    required StoryType storyType,
    required List<HnItem> currentItems,
    int limit = 20,
  }) async => null;
}

HnItem _story(StoryType type, int number) => HnItem(
  id: type.index * 1000 + number,
  type: 'story',
  time: 1,
  by: 'author',
  title: '${type.label} $number',
  score: 42,
  descendants: 5,
);
