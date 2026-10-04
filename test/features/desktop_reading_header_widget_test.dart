import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/ai/ai_content_repository.dart';
import 'package:hacker_pen/src/core/ai/ai_settings_repository.dart';
import 'package:hacker_pen/src/core/api/models/hn_user.dart';
import 'package:hacker_pen/src/core/design_system/design_system.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/core/domain/story_type.dart';
import 'package:hacker_pen/src/core/navigation/app_routes.dart';
import 'package:hacker_pen/src/core/settings/reading_preferences_cubit.dart';
import 'package:hacker_pen/src/features/item_detail/data/item_detail_repository.dart';
import 'package:hacker_pen/src/features/item_detail/domain/comment_node.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/cubit/item_detail_cubit.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/views/item_detail_page.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/widgets/item_detail_summary_body.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/widgets/item_detail_actions_dock.dart';
import 'package:hacker_pen/src/features/items/data/items_repository.dart';
import 'package:hacker_pen/src/features/items/presentation/views/items_page.dart';
import 'package:hacker_pen/src/features/reading/presentation/widgets/reading_pane_header.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../support/fake_webview_platform.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'desktop news and article have one aligned pane header with local actions',
    (tester) async {
      final fixture = _Fixture();
      var hidden = 0;
      var restored = 0;
      var comments = 0;
      var summary = 0;
      var closed = 0;
      await fixture.mount(
        tester,
        width: 1200,
        child: Row(
          children: [
            SizedBox(
              width: 300,
              child: ItemsPage(
                embedded: true,
                wideLayout: true,
                onClose: () => hidden++,
              ),
            ),
            Expanded(
              child: ItemDetailReader(
                embedded: true,
                wideLayout: true,
                onShowNews: () => restored++,
                onComments: () => comments++,
                onSummary: () => summary++,
                onClose: () => closed++,
              ),
            ),
          ],
        ),
      );
      final news = find.byKey(const ValueKey('wide-news-header'));
      final article = find.byKey(const ValueKey('wide-reader-header'));
      expect(tester.getSize(news).height, ReadingPaneHeader.height);
      expect(tester.getSize(article).height, ReadingPaneHeader.height);
      expect(tester.getTopLeft(news).dy, tester.getTopLeft(article).dy);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('web-content'))).dy,
        ReadingPaneHeader.height,
      );
      expect(tester.getTopLeft(find.text('TOP')).dy, greaterThanOrEqualTo(56));
      expect(find.text('HACKERPEN'), findsNothing);
      expect(find.byType(ItemDetailActionsDock), findsNothing);
      expect(find.byKey(const ValueKey('article-metadata')), findsOneWidget);

      await tester.tap(find.byTooltip('Hide news list'));
      await tester.tap(find.byTooltip('Show news list'));
      await tester.tap(find.byKey(const ValueKey('article-comments')));
      await tester.tap(find.byKey(const ValueKey('article-summary')));
      await tester.tap(find.byTooltip('Close article'));
      await tester.tap(find.byTooltip('Refresh news list'));
      await tester.pumpAndSettle();
      expect([hidden, restored, comments, summary, closed], [1, 1, 1, 1, 1]);
      expect(fixture.items.refreshedTypes, [StoryType.top]);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'desktop categories remain visible and directly clickable',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(
        tester,
        width: 300,
        child: const ItemsPage(embedded: true, wideLayout: true),
      );
      for (final type in StoryTypeMetadata.homeTabs) {
        final category = find.text(type.label.toUpperCase());
        expect(category.hitTestable(), findsOneWidget);
        await tester.tap(category);
        await tester.pumpAndSettle();
        expect(find.text('${type.label} story').hitTestable(), findsOneWidget);
        expect(fixture.items.requestedTypes, contains(type));
      }
      expect(find.byType(DropdownButton<StoryType>), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('wide-news-header'))).height,
        56,
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'a narrow desktop article keeps its header and restore control',
    (tester) async {
      var restored = 0;
      final fixture = _Fixture();
      await fixture.mount(
        tester,
        width: 360,
        child: ItemDetailReader(
          embedded: true,
          wideLayout: true,
          onShowNews: () => restored++,
          onComments: () {},
          onSummary: () {},
          onClose: () {},
        ),
      );
      fixture.platform.controller.onScroll!(const ScrollPositionChange(0, 200));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('wide-reader-header'))).height,
        56,
      );
      expect(find.byType(HpCollapsibleHeader), findsNothing);
      await tester.tap(find.byTooltip('Show news list'));
      expect(restored, 1);
      expect(find.byType(ItemDetailActionsDock), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'wide iPad keeps Settings reachable from the News header',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(
        tester,
        width: 300,
        child: const ItemsPage(embedded: true, wideLayout: true),
      );
      await tester.tap(find.byTooltip('Settings').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Settings destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  for (final scale in [2.0, 4.0]) {
    testWidgets(
      'wide iPad article keeps its title and actions at text scale $scale',
      (tester) async {
        var restored = 0;
        var comments = 0;
        var summary = 0;
        var closed = 0;
        final fixture = _Fixture();
        await fixture.mount(
          tester,
          width: 600,
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: ItemDetailReader(
                embedded: true,
                wideLayout: true,
                onShowNews: () => restored++,
                onComments: () => comments++,
                onSummary: () => summary++,
                onClose: () => closed++,
              ),
            ),
          ),
        );
        expect(
          tester
              .getSize(find.byKey(const ValueKey('wide-reader-header')))
              .height,
          56,
        );
        expect(find.text('Article title').hitTestable(), findsOneWidget);
        expect(find.byKey(const ValueKey('article-metadata')), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Show news list'));
        await tester.tap(find.byKey(const ValueKey('article-comments')));
        await tester.tap(find.byKey(const ValueKey('article-summary')));
        await tester.tap(find.byTooltip('Close article'));
        expect([restored, comments, summary, closed], [1, 1, 1, 1]);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  testWidgets('in-tree summary closes through its callback', (tester) async {
    var closed = 0;
    final fixture = _Fixture();
    await fixture.mount(
      tester,
      width: 390,
      child: ItemDetailSummaryBody(
        showSheetHeader: true,
        onClose: () => closed++,
      ),
    );
    await tester.tap(find.byTooltip('Close'));
    expect(closed, 1);
    expect(find.text('Summary'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Fixture {
  final items = _ItemsRepository();
  final details = _DetailRepository();
  final ai = _AiRepository();
  final platform = FakeWebViewPlatform();

  Future<void> mount(
    WidgetTester tester, {
    required double width,
    required Widget child,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    WebViewPlatform.instance = platform;
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ItemsRepository>.value(value: items),
          RepositoryProvider<ItemDetailRepository>.value(value: details),
          RepositoryProvider<AiContentRepository>.value(value: ai),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ReadingPreferencesCubit()..load()),
            BlocProvider(create: (_) => ItemDetailCubit(details, ai)..load(1)),
          ],
          child: MaterialApp(
            theme: HpTheme.dark(),
            routes: {
              AppRoutes.settings: (_) => const Scaffold(
                body: Center(child: Text('Settings destination')),
              ),
            },
            home: child,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    if (find.byKey(const ValueKey('web-content')).evaluate().isNotEmpty) {
      platform.navigation.onFinished('https://example.com/article');
    }
    await tester.pumpAndSettle();
  }
}

class _ItemsRepository implements ItemsRepository {
  final requestedTypes = <StoryType>[];
  final refreshedTypes = <StoryType>[];

  @override
  Future<List<HnItem>> fetchItems({
    StoryType storyType = StoryType.top,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    requestedTypes.add(storyType);
    if (forceRefresh) refreshedTypes.add(storyType);
    return [_story(title: '${storyType.label} story')];
  }

  @override
  Future<List<HnItem>?> refreshVisibleItemsIfChanged({
    required StoryType storyType,
    required List<HnItem> currentItems,
    int limit = 20,
  }) async => currentItems;
}

class _DetailRepository implements ItemDetailRepository {
  @override
  Future<HnItem> fetchStory(int itemId) async => _story();

  @override
  Future<List<CommentNode>> fetchCommentsForStory(HnItem story) async => [];

  @override
  Future<HnItem> fetchUserPreviewItem(int id) async => _story();

  @override
  Future<HnUser> fetchUser(String id) async =>
      HnUser(id: id, created: 1, karma: 1, about: '', submitted: const []);
}

class _AiRepository extends AiContentRepository {
  _AiRepository() : super(settingsRepository: AiSettingsRepository());
}

HnItem _story({String title = 'Article title'}) => HnItem(
  id: 1,
  type: 'story',
  title: title,
  by: 'author',
  score: 10,
  descendants: 0,
  time: 1,
  url: 'https://example.com/article',
);
