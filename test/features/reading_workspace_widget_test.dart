import 'dart:async';

import 'package:cached_query/cached_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/app.dart';
import 'package:hacker_pen/src/core/ai/ai_content_repository.dart';
import 'package:hacker_pen/src/core/ai/ai_provider.dart';
import 'package:hacker_pen/src/core/ai/ai_settings.dart';
import 'package:hacker_pen/src/core/ai/ai_settings_repository.dart';
import 'package:hacker_pen/src/core/ai/ai_translation_mode.dart';
import 'package:hacker_pen/src/core/api/models/hn_user.dart';
import 'package:hacker_pen/src/core/api/hn_query_keys.dart';
import 'package:hacker_pen/src/core/design_system/design_system.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/core/domain/story_type.dart';
import 'package:hacker_pen/src/core/navigation/app_routes.dart';
import 'package:hacker_pen/src/core/platform/macos_settings_bridge.dart';
import 'package:hacker_pen/src/core/settings/reading_preferences_cubit.dart';
import 'package:hacker_pen/src/features/item_detail/data/item_detail_repository.dart';
import 'package:hacker_pen/src/features/item_detail/domain/comment_node.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/widgets/item_detail_summary_body.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/views/user_profile_page.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/widgets/item_detail_actions_dock.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/widgets/item_detail_comments_fab.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/widgets/item_detail_comments_sheet.dart';
import 'package:hacker_pen/src/features/reading/presentation/widgets/reading_pane_header.dart';
import 'package:hacker_pen/src/features/items/data/items_repository.dart';
import 'package:hacker_pen/src/features/items/presentation/widgets/item_story_row.dart';
import 'package:hacker_pen/src/features/reading/presentation/views/reading_workspace_page.dart';
import 'package:hacker_pen/src/features/settings/presentation/views/settings_page.dart';
import 'package:hacker_pen/src/features/settings/presentation/views/privacy_policy_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../support/fake_webview_platform.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'pane toggles interpolate the article width',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 1600);
      await fixture.openStory(tester, 1);
      final controller = fixture.platform.controller;
      final before = tester.getSize(_pane('reader')).width;
      await tester.tap(_articleComments().hitTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final during = tester.getSize(_pane('reader')).width;
      await tester.pumpAndSettle();
      final after = tester.getSize(_pane('reader')).width;
      expect(during, lessThan(before));
      expect(during, greaterThan(after));
      await tester.tap(find.byTooltip('Hide news list').hitTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final expanding = tester.getSize(_pane('reader')).width;
      await tester.pumpAndSettle();
      expect(expanding, greaterThan(after));
      expect(expanding, lessThan(tester.getSize(_pane('reader')).width));
      expect(fixture.platform.controller, same(controller));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('unfinished navigation leaves article content interactive', (
    tester,
  ) async {
    final fixture = _Fixture();
    await fixture.mount(tester, width: 1600);
    await fixture.openStory(tester, 1);
    fixture.platform.navigation.onStarted('https://example.com/slow');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('web-content')).hitTestable(),
      findsOneWidget,
    );
    fixture.platform.navigation.onFinished('https://example.com/slow');
    await tester.pumpAndSettle();
  });

  testWidgets(
    'news is the root and selecting a story opens its article only',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 1200);
      _expectPanes(news: true, reader: false, discussion: false);
      expect(tester.getSize(_pane('news')).width, 1200);
      expect(find.text('SELECT A STORY TO START READING'), findsNothing);
      expect(find.byTooltip('Show website'), findsNothing);
      expect(find.byTooltip('Settings'), findsNothing);

      await fixture.openStory(tester, 1);
      _expectPanes(news: true, reader: true, discussion: false);
      expect(_articleComments().hitTestable(), findsOneWidget);
      expect(_articleSummary().hitTestable(), findsOneWidget);
      expect(find.byTooltip('Close article').hitTestable(), findsOneWidget);
      expect(find.text('Website'), findsNothing);
      expect(find.text('Discussion'), findsNothing);
      expect(fixture.ai.summarizedUrls, isEmpty);
      expect(
        find.byKey(const ValueKey('wide-workspace-toolbar')),
        findsNothing,
      );
      expect(find.byType(ReadingPaneHeader), findsNWidgets(2));
      final newsHeader = find.byKey(const ValueKey('wide-news-header'));
      final articleHeader = find.byKey(const ValueKey('wide-reader-header'));
      expect(tester.getSize(newsHeader).height, 56);
      expect(tester.getSize(articleHeader).height, 56);
      expect(tester.getTopLeft(newsHeader).dy, 0);
      expect(tester.getTopLeft(articleHeader).dy, 0);
      expect(
        tester.getTopLeft(find.text('TOP').hitTestable()).dy,
        greaterThan(56),
      );
      for (final category in ['TOP', 'NEW', 'BEST', 'ASK', 'SHOW']) {
        expect(find.text(category).hitTestable(), findsOneWidget);
      }
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      final inspectorHeader = find.byKey(
        const ValueKey('wide-discussion-header'),
      );
      expect(tester.getSize(inspectorHeader).height, 56);
      expect(tester.getTopLeft(inspectorHeader).dy, 0);
      expect(find.byType(ReadingPaneHeader), findsNWidgets(3));
      expect(find.text('Story 1').hitTestable(), findsNWidgets(2));
      final storyRow = find.byWidgetPredicate(
        (widget) => widget is ItemStoryRow && widget.item.id == 1,
      );
      expect(tester.widget<ItemStoryRow>(storyRow).wideLayout, isTrue);
      expect(tester.getSize(storyRow).height, lessThan(110));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'resizing keeps the parent article and the same inspector mounted',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 1600);
      await fixture.openStory(tester, 1);
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      _expectPanes(news: true, reader: true, discussion: true);
      final controller = fixture.platform.controller;
      final websiteElement = tester.element(
        find.byKey(const ValueKey('web-content')),
      );
      final inspectorElement = tester.element(_pane('discussion'));
      await tester.tap(find.byTooltip('Translate comment').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Translated comment 1').hitTestable(), findsOneWidget);

      await _resize(tester, 900);
      _expectPanes(news: false, reader: true, discussion: true);
      expect(tester.getSize(_pane('reader')).width, greaterThan(500));
      expect(fixture.platform.controller, same(controller));
      expect(tester.element(_pane('discussion')), same(inspectorElement));

      await _resize(tester, 390);
      _expectPanes(news: false, reader: true, discussion: true);
      expect(tester.getSize(_pane('reader')).width, 390);
      expect(find.byKey(const ValueKey('inspector-scrim')), findsOneWidget);
      if (Theme.of(tester.element(_pane('reader'))).platform ==
          TargetPlatform.macOS) {
        expect(tester.getTopLeft(_pane('discussion')).dy, 0);
        expect(find.byType(ItemDetailActionsDock), findsNothing);
      } else {
        expect(tester.getTopLeft(_pane('discussion')).dy, 0);
        expect(
          find.byKey(const ValueKey('wide-discussion-header')),
          findsNothing,
        );
        expect(
          tester.getTopLeft(find.byType(ItemDetailCommentsSheet)).dy,
          closeTo(900 * 0.06, 0.1),
        );
      }
      expect(tester.element(_pane('discussion')), same(inspectorElement));
      expect(fixture.platform.controller, same(controller));

      await _resize(tester, 1600);
      _expectPanes(news: true, reader: true, discussion: true);
      expect(
        tester.element(find.byKey(const ValueKey('web-content'))),
        same(websiteElement),
      );
      expect(tester.element(_pane('discussion')), same(inspectorElement));
      expect(find.text('Translated comment 1').hitTestable(), findsOneWidget);
      expect(fixture.details.requestedStories, [1]);
      expect(fixture.ai.summarizedUrls, isEmpty);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS, TargetPlatform.macOS}),
  );

  testWidgets(
    'narrow Mac keeps desktop controls and one visible header row',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 390);
      expect(
        tester.getSize(find.byKey(const ValueKey('wide-news-header'))).height,
        56,
      );
      await fixture.openStory(tester, 1);
      expect(find.byType(ItemDetailActionsDock), findsNothing);
      expect(find.text('SUMMARY'), findsNothing);
      expect(
        find.byKey(const ValueKey('wide-reader-header')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('wide-discussion-header')))
            .dy,
        0,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('wide-discussion-header')))
            .height,
        56,
      );
      expect(
        find.byKey(const ValueKey('wide-reader-header')).hitTestable(),
        findsNothing,
      );
      expect(find.byTooltip('Close discussion').hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Close discussion').hitTestable());
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('wide-reader-header')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('wide-workspace-toolbar')),
        findsNothing,
      );
      await tester.tap(find.byTooltip('Show news list').hitTestable());
      await tester.pumpAndSettle();
      _expectPanes(news: true, reader: false, discussion: false);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'narrow iPad retains the original hideable actions and collapsible header',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 600);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
      addTearDown(tester.view.resetPadding);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('wide-news-header')), findsNothing);
      await fixture.openStory(tester, 1);
      final article = tester.element(find.byKey(const ValueKey('web-content')));
      final header = find.byType(HpCollapsibleHeader);
      expect(tester.getSize(header).height, 100);
      expect(tester.getTopLeft(header).dy, 0);
      expect(find.text('SUMMARY').hitTestable(), findsOneWidget);
      expect(find.text('1 COMMENTS').hitTestable(), findsOneWidget);
      expect(find.byKey(const ValueKey('wide-reader-header')), findsNothing);
      fixture.platform.controller.onScroll!(const ScrollPositionChange(0, 2));
      await tester.pumpAndSettle();
      expect(find.text('SUMMARY').hitTestable(), findsNothing);
      await tester.drag(
        find.byType(ItemDetailActionsDock),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('SUMMARY').hitTestable(), findsOneWidget);
      for (double y = 0; y <= 150; y += 3) {
        fixture.platform.controller.onScroll!(ScrollPositionChange(0, y));
      }
      await tester.pumpAndSettle();
      expect(tester.getSize(header).height, 0);
      expect(
        tester.element(find.byKey(const ValueKey('web-content'))),
        same(article),
      );
      fixture.platform.controller.onScroll!(const ScrollPositionChange(0, 125));
      await tester.pumpAndSettle();
      expect(tester.getSize(header).height, 100);
      expect(
        find.byKey(const ValueKey('wide-workspace-toolbar')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'comments and summary scroll from zero in wide iPad and retain positions on resize',
    (tester) async {
      final fixture = _Fixture();
      fixture.details.commentCount = 50;
      fixture.ai.longSummary = true;
      await fixture.mount(tester, width: 1600);
      await fixture.openStory(tester, 1);
      final webElement = tester.element(
        find.byKey(const ValueKey('web-content')),
      );
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      final commentsElement = tester.element(_commentsList());
      expect(_scrollOffset(tester, _commentsList()), 0);
      await tester.drag(_commentsList(), const Offset(0, -300));
      await tester.pumpAndSettle();
      final commentsOffset = _scrollOffset(tester, _commentsList());
      expect(commentsOffset, greaterThan(100));
      await tester.tap(_articleSummary().hitTestable());
      await tester.pumpAndSettle();
      final summaryElement = tester.element(_summaryList());
      expect(_scrollOffset(tester, _summaryList()), 0);
      await tester.drag(_summaryList(), const Offset(0, -280));
      await tester.pumpAndSettle();
      final summaryOffset = _scrollOffset(tester, _summaryList());
      expect(summaryOffset, greaterThan(100));

      await _resize(tester, 600);
      expect(tester.element(_commentsList()), same(commentsElement));
      expect(tester.element(_summaryList()), same(summaryElement));
      expect(
        _scrollOffset(tester, _commentsList()),
        closeTo(commentsOffset, 0.1),
      );
      expect(
        _scrollOffset(tester, _summaryList()),
        closeTo(summaryOffset, 0.1),
      );
      final summarySheet = tester.widget<DraggableScrollableSheet>(
        find.byKey(const ValueKey('summary-sheet')),
      );
      expect(summarySheet.initialChildSize, 0.55);
      expect(summarySheet.minChildSize, 0.35);
      expect(summarySheet.maxChildSize, 0.92);
      expect(summarySheet.controller!.size, closeTo(0.55, 0.001));
      final summaryBody = find.byType(ItemDetailSummaryBody).hitTestable();
      expect(tester.getTopLeft(summaryBody).dy, closeTo(900 * 0.45, 0.1));
      await tester.drag(_summaryList().hitTestable(), const Offset(0, -120));
      await tester.pumpAndSettle();
      final narrowSummaryOffset = _scrollOffset(tester, _summaryList());
      await _resize(tester, 1600);
      expect(
        _scrollOffset(tester, _summaryList()),
        closeTo(narrowSummaryOffset, 0.1),
      );
      expect(tester.element(_summaryList()), same(summaryElement));
      await tester.tap(find.text('Comments 1').hitTestable());
      await tester.pumpAndSettle();
      expect(
        _scrollOffset(tester, _commentsList()),
        closeTo(commentsOffset, 0.1),
      );
      await _resize(tester, 600);
      final commentsSheet = tester.widget<DraggableScrollableSheet>(
        find.byKey(const ValueKey('comments-sheet')),
      );
      expect(commentsSheet.initialChildSize, 0.94);
      expect(commentsSheet.minChildSize, 0.55);
      expect(commentsSheet.maxChildSize, 1);
      expect(commentsSheet.snapSizes, [0.94, 1]);
      expect(commentsSheet.controller!.size, closeTo(0.94, 0.001));
      expect(
        tester.getTopLeft(find.byType(ItemDetailCommentsSheet)).dy,
        closeTo(900 * 0.06, 0.1),
      );
      expect(find.byTooltip('Close').hitTestable(), findsOneWidget);
      expect(
        tester.element(find.byKey(const ValueKey('web-content'))),
        same(webElement),
      );
      expect(fixture.details.requestedStories, [1]);
      expect(fixture.ai.summarizedUrls, [_story(1).url]);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'narrow iPad sheet headers and drag dismissal return to the article',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 600);
      await fixture.openStory(tester, 1);
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('COMMENTS 1').hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Close').hitTestable());
      await tester.pumpAndSettle();
      _expectPanes(news: false, reader: true, discussion: false);
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      await tester.drag(
        find.text('COMMENTS 1').hitTestable(),
        const Offset(0, 450),
      );
      await tester.pumpAndSettle();
      _expectPanes(news: false, reader: true, discussion: false);
      await tester.tap(find.text('SUMMARY').hitTestable());
      await tester.pumpAndSettle();
      final summarySheet = tester.widget<DraggableScrollableSheet>(
        find.byKey(const ValueKey('summary-sheet')),
      );
      expect(summarySheet.controller!.size, closeTo(0.55, 0.001));
      expect(find.byTooltip('Close').hitTestable(), findsOneWidget);
      await tester.drag(_summaryList().hitTestable(), const Offset(0, 250));
      await tester.pumpAndSettle();
      _expectPanes(news: false, reader: true, discussion: false);
      expect(fixture.ai.summarizedUrls, [_story(1).url]);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'sidebars collapse independently and medium widths preserve the news preference',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 1600);
      await fixture.openStory(tester, 1);
      await tester.tap(find.byTooltip('Hide news list').hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      _expectPanes(news: false, reader: true, discussion: true);

      await _resize(tester, 900);
      await tester.tap(find.byTooltip('Close discussion').hitTestable());
      await tester.pumpAndSettle();
      _expectPanes(news: false, reader: true, discussion: false);
      await tester.tap(find.byTooltip('Show news list').hitTestable());
      await tester.pumpAndSettle();
      _expectPanes(news: true, reader: true, discussion: false);

      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      _expectPanes(news: false, reader: true, discussion: true);
      await tester.tap(find.byTooltip('Close discussion').hitTestable());
      await tester.pumpAndSettle();
      _expectPanes(news: true, reader: true, discussion: false);

      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Show news list').hitTestable());
      await tester.pumpAndSettle();
      _expectPanes(news: true, reader: true, discussion: false);
      await _resize(tester, 1600);
      _expectPanes(news: true, reader: true, discussion: false);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'closing the article closes its inspector and returns to the news root',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 1200);
      await fixture.openStory(tester, 1);
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hide news list').hitTestable());
      await tester.pumpAndSettle();
      _expectPanes(news: false, reader: true, discussion: true);

      await tester.tap(find.byTooltip('Close article').hitTestable());
      await tester.pumpAndSettle();
      _expectPanes(news: true, reader: false, discussion: false);
      expect(tester.getSize(_pane('news')).width, 1200);
      expect(find.byKey(const ValueKey('web-content')), findsNothing);
      expect(find.byTooltip('Close discussion'), findsNothing);
      expect(find.byTooltip('Show news list'), findsNothing);
      await fixture.openStory(tester, 2);
      _expectPanes(news: true, reader: true, discussion: false);
      expect(fixture.platform.controller.loadedUri, Uri.parse(_story(2).url!));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'the open inspector follows a new article and retains its comments tab',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 1200);
      await fixture.openStory(tester, 1);
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Comment for story 1').hitTestable(), findsOneWidget);

      await fixture.openStory(tester, 2);
      _expectPanes(news: true, reader: true, discussion: true);
      expect(find.text('Comment for story 2').hitTestable(), findsOneWidget);
      expect(find.text('Comment for story 1'), findsNothing);
      expect(fixture.platform.controller.loadedUri, Uri.parse(_story(2).url!));
      expect(fixture.ai.summarizedUrls, isEmpty);
      expect(fixture.details.requestedStories, [1, 2]);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'the summary tab follows selection without automatically generating another summary',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 1600);
      await fixture.openStory(tester, 1);
      await tester.tap(_articleSummary().hitTestable());
      await tester.pumpAndSettle();
      expect(fixture.ai.summarizedUrls, [_story(1).url]);
      expect(find.text('Summary for story 1').hitTestable(), findsOneWidget);

      await fixture.openStory(tester, 2);
      _expectPanes(news: true, reader: true, discussion: true);
      expect(find.text('Generate summary').hitTestable(), findsOneWidget);
      expect(find.text('Summary for story 1'), findsNothing);
      expect(find.text('Comment for story 2').hitTestable(), findsNothing);
      expect(fixture.ai.summarizedUrls, [_story(1).url]);
      await tester.tap(find.text('Generate summary').hitTestable());
      await tester.pumpAndSettle();
      expect(fixture.ai.summarizedUrls, [_story(1).url, _story(2).url]);
      expect(find.text('Summary for story 2').hitTestable(), findsOneWidget);

      await tester.tap(find.text('Comments 1').hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Summary').hitTestable());
      await tester.pumpAndSettle();
      expect(fixture.ai.summarizedUrls, hasLength(2));
      await _resize(tester, 390);
      await _resize(tester, 1600);
      expect(fixture.ai.summarizedUrls, hasLength(2));
      expect(find.text('Summary for story 2').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Summary stays disabled until the newly selected article has loaded',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 1600);
      await fixture.openStory(tester, 1);
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();

      final nextStory = Completer<HnItem>();
      fixture.details.storyResponses[2] = nextStory.future;
      await tester.tap(_feedStory(2).hitTestable());
      await tester.pump();
      final summaryTab = find.ancestor(
        of: find.text('Summary').hitTestable(),
        matching: find.byType(TextButton),
      );
      expect(tester.widget<TextButton>(summaryTab).onPressed, isNull);
      await tester.tap(find.text('Summary').hitTestable());
      await tester.pump();
      expect(fixture.ai.summarizedUrls, isEmpty);
      expect(
        find.text('Only stories with a URL can be summarized.'),
        findsNothing,
      );

      nextStory.complete(_story(2));
      await tester.pump();
      await tester.pump();
      fixture.platform.navigation.onFinished(_story(2).url!);
      await tester.pumpAndSettle();
      expect(fixture.ai.summarizedUrls, isEmpty);
      await tester.tap(find.text('Summary').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Summary for story 2').hitTestable(), findsOneWidget);
      expect(fixture.ai.summarizedUrls, [_story(2).url]);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'a narrow iPad uses the original comments sheet over its mounted article',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 360);
      tester.view.physicalSize = const Size(360, 480);
      await tester.pumpAndSettle();
      _expectPanes(news: true, reader: false, discussion: false);
      await fixture.openStory(tester, 1);
      final controller = fixture.platform.controller;
      final websiteElement = tester.element(
        find.byKey(const ValueKey('web-content')),
      );
      _expectPanes(news: false, reader: true, discussion: false);
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      _expectPanes(news: false, reader: true, discussion: true);
      expect(find.text('Comment for story 1').hitTestable(), findsOneWidget);
      expect(
        tester.element(find.byKey(const ValueKey('web-content'))),
        same(websiteElement),
      );

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      _expectPanes(news: false, reader: true, discussion: false);
      expect(fixture.platform.controller, same(controller));
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      _expectPanes(news: false, reader: true, discussion: false);
      await _command(tester, LogicalKeyboardKey.bracketLeft);
      _expectPanes(news: true, reader: false, discussion: false);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'system back dismisses the inspector before closing its parent article',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 390);
      await fixture.openStory(tester, 1);
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      _expectPanes(news: false, reader: true, discussion: false);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      _expectPanes(news: true, reader: false, discussion: false);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'desktop shortcuts operate supporting panes and settings without replacing the article',
    (tester) async {
      var settingsOpened = 0;
      const channel = MethodChannel('dev.suica.hackerPen/settings');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        expect(call.method, 'openSettings');
        settingsOpened++;
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final fixture = _Fixture();
      await fixture.mount(tester, width: 1600);
      await fixture.openStory(tester, 1);
      final controller = fixture.platform.controller;
      await _command(tester, LogicalKeyboardKey.keyB);
      _expectPanes(news: false, reader: true, discussion: false);
      await _command(tester, LogicalKeyboardKey.keyB, shift: true);
      _expectPanes(news: false, reader: true, discussion: true);
      await _command(tester, LogicalKeyboardKey.keyB, shift: true);
      _expectPanes(news: false, reader: true, discussion: false);
      await _command(tester, LogicalKeyboardKey.keyB);
      _expectPanes(news: true, reader: true, discussion: false);
      await _command(tester, LogicalKeyboardKey.digit2);
      _expectPanes(news: true, reader: true, discussion: false);
      expect(fixture.platform.controller, same(controller));
      expect(fixture.ai.summarizedUrls, isEmpty);

      await tester.tap(find.text('ASK').hitTestable());
      await tester.pumpAndSettle();
      await _command(tester, LogicalKeyboardKey.keyR);
      expect(fixture.items.refreshedTypes, [StoryType.ask]);
      fixture.items.refreshError = StateError('offline');
      await _command(tester, LogicalKeyboardKey.keyR);
      expect(
        find.text('Could not refresh. Try refreshing again.'),
        findsOneWidget,
      );
      expect(_feedStory(1).hitTestable(), findsOneWidget);
      await _command(tester, LogicalKeyboardKey.comma);
      expect(settingsOpened, 1);
      expect(find.byType(SettingsPage), findsNothing);
      expect(fixture.platform.controller, same(controller));
      _expectPanes(news: true, reader: true, discussion: false);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'native actions respect the current route and restore the parent workspace handler',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 1600);
      await fixture.openStory(tester, 1);
      final controller = fixture.platform.controller;
      final parentHandler = MacosSettingsBridge.workspaceActionHandler!;

      parentHandler('toggleNews');
      await tester.pumpAndSettle();
      _expectPanes(news: false, reader: true, discussion: false);
      parentHandler('toggleNews');
      parentHandler('toggleInspector');
      await tester.pumpAndSettle();
      _expectPanes(news: true, reader: true, discussion: true);
      parentHandler('back');
      await tester.pumpAndSettle();

      final navigator = Navigator.of(
        tester.element(find.byType(ReadingWorkspacePage)),
      );
      navigator.pushNamed(AppRoutes.userProfile, arguments: 'author1');
      await tester.pumpAndSettle();
      expect(find.byType(UserProfilePage), findsOneWidget);
      parentHandler('toggleNews');
      parentHandler('toggleInspector');
      await tester.pumpAndSettle();

      navigator.pushNamed(AppRoutes.itemDetail, arguments: 2);
      await tester.pump();
      await tester.pump();
      fixture.platform.navigation.onFinished(_story(2).url!);
      await tester.pumpAndSettle();
      final nestedHandler = MacosSettingsBridge.workspaceActionHandler!;
      expect(nestedHandler, isNot(parentHandler));
      nestedHandler('toggleInspector');
      await tester.pumpAndSettle();
      expect(find.text('Comment for story 2').hitTestable(), findsOneWidget);
      nestedHandler('back');
      await tester.pumpAndSettle();
      _expectPanes(news: true, reader: true, discussion: false);
      nestedHandler('back');
      await tester.pumpAndSettle();
      _expectPanes(news: true, reader: false, discussion: false);
      nestedHandler('back');
      await tester.pumpAndSettle();
      expect(find.byType(UserProfilePage), findsOneWidget);
      expect(MacosSettingsBridge.workspaceActionHandler, parentHandler);
      parentHandler('back');
      await tester.pumpAndSettle();
      _expectPanes(news: true, reader: true, discussion: false);
      expect(
        tester
            .widget<WebViewWidget>(find.byType(WebViewWidget))
            .platform
            .params
            .controller,
        same(controller),
      );
      expect(fixture.ai.summarizedUrls, isEmpty);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'AI settings changes invalidate results without navigating or reloading the article',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 1600);
      await fixture.openStory(tester, 1);
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Translate comment').hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Summary').hitTestable());
      await tester.pumpAndSettle();
      final controller = fixture.platform.controller;
      expect(fixture.ai.summarizedUrls, [_story(1).url]);
      await tester.runAsync(
        () => AiSettingsRepository().save(
          AiSettings.defaultsFor(
            AiProviderId.openAiCompatible,
          ).copyWith(targetLanguage: 'Japanese'),
        ),
      );
      await tester.pumpAndSettle();
      _expectPanes(news: true, reader: true, discussion: true);
      expect(find.text('Generate summary').hitTestable(), findsOneWidget);
      expect(find.text('Summary for story 1'), findsNothing);
      expect(find.text('Translated comment 1'), findsNothing);
      expect(fixture.platform.controller, same(controller));
      expect(fixture.details.requestedStories, [1]);
      expect(fixture.ai.summarizedUrls, [_story(1).url]);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.macOS, TargetPlatform.iOS}),
  );

  testWidgets(
    'a new workspace starts at news with no restored article or inspector',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester, width: 1600);
      await fixture.openStory(tester, 1);
      await tester.tap(_articleComments().hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hide news list').hitTestable());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();
      _expectPanes(news: true, reader: false, discussion: false);
      expect(tester.getSize(_pane('news')).width, 1600);
      expect(find.byKey(const ValueKey('web-content')), findsNothing);
      expect(fixture.details.requestedStories, [1]);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'global back shortcuts leave nested settings and a focused key form',
    (tester) async {
      CachedQuery.instance.reset();
      CachedQuery.instance.config(
        config: const GlobalQueryConfig(ignoreCacheDuration: true),
      );
      addTearDown(() => CachedQuery.instance.reset());
      FlutterSecureStorage.setMockInitialValues({});
      for (final type in StoryType.values) {
        await Query<List<int>>(
          key: HnQueryKeys.storyIds(type),
          queryFn: () async => [],
        ).fetch();
      }
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1600, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(const HackerPenApp(useWorkspace: true));
      await tester.pumpAndSettle();

      await _command(tester, LogicalKeyboardKey.comma);
      expect(find.byType(SettingsPage), findsOneWidget);
      await tester.tap(find.text('Providers & keys'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add API key'));
      await tester.pumpAndSettle();
      expect(find.text('Choose key provider'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Choose key provider'), findsNothing);

      await tester.tap(find.text('Add API key'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      await _command(tester, LogicalKeyboardKey.bracketLeft);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Add API key'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Providers & keys'), findsOneWidget);

      await tester.ensureVisible(find.text('Privacy Policy'));
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyPolicyPage), findsOneWidget);
      await _command(tester, LogicalKeyboardKey.bracketLeft);
      expect(find.byType(PrivacyPolicyPage), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(ReadingWorkspacePage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await CachedQuery.instance.dispose();
      CachedQuery.instance.reset();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}

Finder _pane(String name) => find.byKey(ValueKey('$name-pane'));

Finder _articleComments() {
  final desktop = find.byKey(const ValueKey('article-comments'));
  return desktop.evaluate().isNotEmpty
      ? desktop
      : find.byType(ItemDetailCommentsFab);
}

Finder _articleSummary() => find.descendant(
  of: _pane('reader'),
  matching: find.byTooltip(RegExp(r'^(Summary|Summarize)$')),
);

Finder _commentsList() => find.descendant(
  of: find.byType(ItemDetailCommentsBody, skipOffstage: false),
  matching: find.byType(ListView, skipOffstage: false),
  skipOffstage: false,
);

Finder _summaryList() => find.descendant(
  of: find.byType(ItemDetailSummaryBody, skipOffstage: false),
  matching: find.byType(ListView, skipOffstage: false),
  skipOffstage: false,
);

double _scrollOffset(WidgetTester tester, Finder list) =>
    tester.widget<ListView>(list).controller!.position.pixels;

Finder _feedStory(int id) =>
    find.descendant(of: _pane('news'), matching: find.text('Story $id'));

void _expectPanes({
  required bool news,
  required bool reader,
  required bool discussion,
}) {
  expect(_pane('news'), news ? findsOneWidget : findsNothing);
  expect(_pane('reader'), reader ? findsOneWidget : findsNothing);
  expect(_pane('discussion'), discussion ? findsOneWidget : findsNothing);
}

Future<void> _resize(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  await tester.pumpAndSettle();
}

Future<void> _command(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  await tester.pumpAndSettle();
}

class _Fixture {
  final items = _FakeItemsRepository();
  final details = _FakeItemDetailRepository();
  final settings = _FakeAiSettingsRepository();
  final ai = _FakeAiContentRepository();
  final platform = FakeWebViewPlatform();

  Future<void> mount(WidgetTester tester, {required double width}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    WebViewPlatform.instance = platform;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
  }

  Widget app() => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ItemsRepository>.value(value: items),
      RepositoryProvider<ItemDetailRepository>.value(value: details),
      RepositoryProvider<AiSettingsRepository>.value(value: settings),
      RepositoryProvider<AiContentRepository>.value(value: ai),
    ],
    child: BlocProvider(
      create: (_) => ReadingPreferencesCubit()..load(),
      child: MaterialApp(
        theme: HpTheme.dark(),
        onGenerateRoute: (settings) =>
            AppRoutes.onGenerateRoute(settings, useWorkspace: true),
        home: const ReadingWorkspacePage(),
      ),
    ),
  );

  Future<void> openStory(WidgetTester tester, int id) async {
    await tester.tap(_feedStory(id).hitTestable());
    await tester.pump();
    await tester.pump();
    platform.navigation.onFinished(_story(id).url!);
    await tester.pumpAndSettle();
  }
}

class _FakeItemsRepository implements ItemsRepository {
  final refreshedTypes = <StoryType>[];
  Object? refreshError;

  @override
  Future<List<HnItem>> fetchItems({
    StoryType storyType = StoryType.top,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      refreshedTypes.add(storyType);
      if (refreshError != null) throw refreshError!;
    }
    return [_story(1), _story(2)];
  }

  @override
  Future<List<HnItem>?> refreshVisibleItemsIfChanged({
    required StoryType storyType,
    required List<HnItem> currentItems,
    int limit = 20,
  }) async => currentItems;
}

class _FakeItemDetailRepository implements ItemDetailRepository {
  final requestedStories = <int>[];
  final storyResponses = <int, Future<HnItem>>{};
  int commentCount = 1;

  @override
  Future<HnItem> fetchStory(int itemId) async {
    requestedStories.add(itemId);
    if (storyResponses[itemId] case final response?) return response;
    return _story(itemId);
  }

  @override
  Future<List<CommentNode>> fetchCommentsForStory(HnItem story) async =>
      List.generate(
        commentCount,
        (index) => CommentNode(
          comment: HnItem(
            id: story.id * 1000 + index,
            type: 'comment',
            time: 1,
            by: 'commenter',
            title: '',
            score: 0,
            descendants: 0,
            text: index == 0
                ? 'Comment for story ${story.id}'
                : 'Additional comment $index for story ${story.id}.',
          ),
          children: const [],
        ),
      );

  @override
  Future<HnUser> fetchUser(String id) async => HnUser(
    id: id,
    created: 1,
    karma: 42,
    about: 'Profile text.',
    submitted: const [1, 2],
  );

  @override
  Future<HnItem> fetchUserPreviewItem(int id) async => _story(id);
}

class _FakeAiSettingsRepository extends AiSettingsRepository {
  @override
  Future<AiSettings> load({AiProviderId? providerId}) async =>
      AiSettings.defaultsFor(providerId ?? AiProviderId.openAiCompatible);

  @override
  Future<String?> readApiKey(AiProviderId providerId) async => null;
}

class _FakeAiContentRepository extends AiContentRepository {
  _FakeAiContentRepository()
    : super(settingsRepository: _FakeAiSettingsRepository());

  final summarizedUrls = <String>[];
  bool longSummary = false;

  @override
  Future<String> summarizeWebPageUrl(String url) async {
    summarizedUrls.add(url);
    return longSummary
        ? List.generate(
            80,
            (index) =>
                'Summary paragraph $index. Article context and details for continued reading.',
          ).join('\n\n')
        : 'Summary for story ${Uri.parse(url).pathSegments.last}';
  }

  @override
  Future<String> translateComment(String rawCommentText) async =>
      'Translated comment ${rawCommentText.split(' ').last}';

  @override
  Future<AiTranslationMode> loadTranslationMode() async =>
      AiTranslationMode.replaceOriginal;
}

HnItem _story(int id) => HnItem(
  id: id,
  type: 'story',
  time: 1,
  by: 'author$id',
  title: 'Story $id',
  score: id * 10,
  descendants: 1,
  url: 'https://example.com/story/$id',
);
