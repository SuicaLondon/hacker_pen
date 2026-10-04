import 'package:hacker_pen/src/features/item_detail/presentation/widgets/item_detail_actions_dock.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hacker_pen/src/core/settings/reading_preferences_cubit.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../support/fake_webview_platform.dart';
import 'package:hacker_pen/src/core/ai/ai_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/ai/ai_content_repository.dart';
import 'package:hacker_pen/src/core/ai/ai_provider.dart';
import 'package:hacker_pen/src/core/ai/ai_settings.dart';
import 'package:hacker_pen/src/core/ai/ai_settings_repository.dart';
import 'package:hacker_pen/src/core/ai/ai_translation_mode.dart';
import 'package:hacker_pen/src/core/api/models/hn_user.dart';
import 'package:hacker_pen/src/core/design_system/design_system.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/core/domain/story_type.dart';
import 'package:hacker_pen/src/core/navigation/app_routes.dart';
import 'package:hacker_pen/src/features/item_detail/data/item_detail_repository.dart';
import 'package:hacker_pen/src/features/item_detail/domain/comment_node.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/views/item_detail_page.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/views/user_profile_page.dart';
import 'package:hacker_pen/src/features/items/data/items_repository.dart';
import 'package:hacker_pen/src/features/items/presentation/views/items_page.dart';
import 'package:hacker_pen/src/features/settings/presentation/views/settings_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('ItemsPage renders success feed, tabs, and error state', (
    tester,
  ) async {
    _setPhoneSize(tester);

    final repository = _FakeItemsRepository(items: [_story(1), _story(2)]);

    await tester.pumpWidget(
      _TestApp(
        repositories: [
          RepositoryProvider<ItemsRepository>.value(value: repository),
        ],
        child: const ItemsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HACKERPEN'), findsOneWidget);
    expect(find.text('TOP STORIES'), findsNothing);
    expect(find.text('story 1'), findsOneWidget);
    expect(find.text('TOP'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);

    await tester.tap(find.text('ASK'));
    await tester.pumpAndSettle();
    expect(repository.requestedTypes, contains(StoryType.ask));

    repository.error = StateError('offline');
    await tester.tap(find.text('SHOW'));
    await tester.pumpAndSettle();
    expect(find.text('Failed to load items'), findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);
  });

  testWidgets('ItemDetailPage renders self post and opens comments sheet', (
    tester,
  ) async {
    _setPhoneSize(tester);

    await tester.pumpWidget(
      _TestApp(
        repositories: [
          RepositoryProvider<AiContentRepository>.value(
            value: _FakeAiContentRepository(),
          ),
          RepositoryProvider<ItemDetailRepository>.value(
            value: _FakeItemDetailRepository(),
          ),
        ],
        child: const ItemDetailPage(itemId: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Self post title'), findsOneWidget);
    expect(find.textContaining('Self post body'), findsOneWidget);
    expect(find.text('1 COMMENTS'), findsOneWidget);

    await tester.tap(find.text('1 COMMENTS'));
    await tester.pumpAndSettle();

    expect(find.text('COMMENTS 1'), findsOneWidget);
    expect(find.text('commenter'), findsOneWidget);
    expect(find.text('A useful comment'), findsOneWidget);
    expect(find.byTooltip('Translate comment'), findsOneWidget);

    await tester.tap(find.byTooltip('Translate comment'));
    await tester.pumpAndSettle();
    expect(find.text('Translated comment'), findsOneWidget);
  });

  testWidgets('ItemDetailPage shows summary actions and summary sheet', (
    tester,
  ) async {
    _setPhoneSize(tester);

    final aiRepository = _FakeAiContentRepository(summary: 'Summary result');

    await tester.pumpWidget(
      _TestApp(
        repositories: [
          RepositoryProvider<AiContentRepository>.value(value: aiRepository),
          RepositoryProvider<ItemDetailRepository>.value(
            value: _FakeItemDetailRepository(storyUrl: 'https://example.com'),
          ),
        ],
        child: const ItemDetailPage(itemId: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Summarize'), findsOneWidget);
    expect(find.text('SUMMARY'), findsOneWidget);

    await tester.tap(find.text('SUMMARY'));
    await tester.pumpAndSettle();

    expect(aiRepository.summarizedUrls, ['https://example.com']);
    expect(find.text('Summary result'), findsOneWidget);
  });

  testWidgets(
    'web loading, scroll direction, navigation, and failure share the page chrome',
    (tester) async {
      _setPhoneSize(tester);
      final platform = FakeWebViewPlatform();
      WebViewPlatform.instance = platform;
      await tester.pumpWidget(
        _TestApp(
          repositories: [
            RepositoryProvider<AiContentRepository>.value(
              value: _FakeAiContentRepository(),
            ),
            RepositoryProvider<ItemDetailRepository>.value(
              value: _FakeItemDetailRepository(storyUrl: 'https://example.com'),
            ),
          ],
          child: const ItemDetailPage(itemId: 1),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        find.byKey(const ValueKey('web-content')).hitTestable(),
        findsOneWidget,
      );
      expect(platform.controller.loadedUri, Uri.parse('https://example.com'));

      platform.navigation.onFinished('https://example.com');
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      final header = find.byType(HpCollapsibleHeader);
      expect(tester.getSize(header).height, 76);
      final webElement = tester.element(
        find.byKey(const ValueKey('web-content')),
      );

      // Even a small scroll closes the actions while the header stays visible.
      platform.controller.onScroll!(const ScrollPositionChange(0, 2));
      await tester.pumpAndSettle();
      expect(tester.getSize(header).height, 76);
      expect(find.text('SUMMARY').hitTestable(), findsNothing);
      await tester.drag(
        find.byType(ItemDetailActionsDock),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('SUMMARY').hitTestable(), findsOneWidget);

      for (double y = 0; y <= 150; y += 3) {
        platform.controller.onScroll!(ScrollPositionChange(0, y));
      }
      await tester.pumpAndSettle();
      expect(tester.getSize(header).height, 0);
      expect(find.byTooltip('Back').hitTestable(), findsNothing);
      expect(
        tester.element(find.byKey(const ValueKey('web-content'))),
        webElement,
      );

      platform.controller.onScroll!(const ScrollPositionChange(0, 125));
      await tester.pumpAndSettle();
      expect(tester.getSize(header).height, 76);
      expect(find.text('SUMMARY').hitTestable(), findsNothing);
      await tester.drag(
        find.byType(ItemDetailActionsDock),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('SUMMARY').hitTestable(), findsOneWidget);
      platform.controller.onScroll!(const ScrollPositionChange(0, 126));
      await tester.pumpAndSettle();
      expect(tester.getSize(header).height, 76);
      expect(find.text('SUMMARY').hitTestable(), findsNothing);
      platform.controller.onScroll!(const ScrollPositionChange(0, 220));
      await tester.pumpAndSettle();
      expect(tester.getSize(header).height, 0);

      platform.navigation.onStarted('https://example.com/next');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getSize(header).height, 76);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      platform.navigation.onError(
        WebResourceError(
          errorCode: -1,
          description: 'offline',
          isForMainFrame: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('Unable to load this page'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(platform.controller.reloads, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      platform.controller.onScroll!(const ScrollPositionChange(0, 500));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'bottom bounce and viewport corrections do not toggle the header',
    (tester) async {
      _setPhoneSize(tester);
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.resetPadding);
      final platform = FakeWebViewPlatform();
      WebViewPlatform.instance = platform;
      await tester.pumpWidget(
        _TestApp(
          repositories: [
            RepositoryProvider<AiContentRepository>.value(
              value: _FakeAiContentRepository(),
            ),
            RepositoryProvider<ItemDetailRepository>.value(
              value: _FakeItemDetailRepository(storyUrl: 'https://example.com'),
            ),
          ],
          child: const ItemDetailPage(itemId: 1),
        ),
      );
      await tester.pump();
      await tester.pump();
      platform.navigation.onFinished('https://example.com');
      await tester.pumpAndSettle();
      final web = find.byKey(const ValueKey('web-content'));
      final header = find.byType(HpCollapsibleHeader);
      final gesture = await tester.startGesture(tester.getCenter(web));
      await gesture.moveBy(const Offset(0, -60));
      platform.controller.onScroll!(const ScrollPositionChange(0, 930));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getSize(header).height, 0);

      // Native bottom bounce and viewport resizing can both reverse offsets
      // without the reader reversing their gesture.
      for (final y in [900.0, 930.0, 880.0, 915.0, 800.0]) {
        platform.controller.onScroll!(ScrollPositionChange(0, y));
        await tester.pumpAndSettle();
        expect(tester.getSize(header).height, 0);
      }

      final reverse = await tester.startGesture(tester.getCenter(web));
      await reverse.moveBy(const Offset(0, 40));
      platform.controller.onScroll!(const ScrollPositionChange(0, 760));
      await reverse.up();
      await tester.pumpAndSettle();
      expect(tester.getSize(header).height, 123);
      platform.controller.onScroll!(const ScrollPositionChange(0, 850));
      await tester.pumpAndSettle();
      expect(tester.getSize(header).height, 123);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'web content fills the top inset only when enabled and the header is hidden',
    (tester) async {
      _setPhoneSize(tester);
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.resetPadding);
      final platform = FakeWebViewPlatform();
      WebViewPlatform.instance = platform;
      await tester.pumpWidget(
        _TestApp(
          repositories: [
            RepositoryProvider<AiContentRepository>.value(
              value: _FakeAiContentRepository(),
            ),
            RepositoryProvider<ItemDetailRepository>.value(
              value: _FakeItemDetailRepository(storyUrl: 'https://example.com'),
            ),
          ],
          child: const ItemDetailPage(itemId: 1),
        ),
      );
      await tester.pump();
      await tester.pump();
      platform.navigation.onFinished('https://example.com');
      await tester.pumpAndSettle();
      final web = find.byKey(const ValueKey('web-content'));
      final webElement = tester.element(web);
      final preferences = tester
          .element(find.byType(ItemDetailPage))
          .read<ReadingPreferencesCubit>();
      expect(tester.getTopLeft(web).dy, 123);
      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsNothing);

      await tester.tap(find.byTooltip('Keep top safe area'));
      await tester.pumpAndSettle();
      expect(preferences.state, isFalse);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen_exit), findsNothing);
      expect(tester.element(web), webElement);
      await tester.tap(find.byTooltip('Extend page to top'));
      await tester.pumpAndSettle();
      expect(preferences.state, isTrue);
      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'reading.extend_page_behind_status_bar',
        ),
        isTrue,
      );

      platform.controller.onScroll!(const ScrollPositionChange(0, 150));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(web).dy, 0);
      expect(find.text('SUMMARY').hitTestable(), findsNothing);
      expect(find.byType(ItemDetailActionsDock).hitTestable(), findsOneWidget);
      expect(SystemChrome.latestStyle?.statusBarColor, Colors.transparent);

      await preferences.setExtendPageBehindStatusBar(false);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(web).dy, 47);
      expect(SystemChrome.latestStyle?.statusBarColor, HpColors.dark.paper);
      expect(tester.element(web), webElement);

      await preferences.setExtendPageBehindStatusBar(true);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(web).dy, 0);
      platform.controller.onScroll!(const ScrollPositionChange(0, 100));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(web).dy, 123);
      expect(find.byTooltip('Back').hitTestable(), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('reading toggle saves its choice when settings is reopened', (
    tester,
  ) async {
    _setPhoneSize(tester);
    final repository = _FakeAiSettingsRepository(
      settings: AiSettings.defaultsFor(AiProviderId.openAiCompatible),
    );
    Widget settingsApp() => _TestApp(
      repositories: [
        RepositoryProvider<AiSettingsRepository>.value(value: repository),
      ],
      child: const SettingsPage(),
    );
    await tester.pumpWidget(settingsApp());
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('READING')).dy,
      greaterThan(tester.getTopLeft(find.text('TRANSLATION')).dy),
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    await tester.tap(find.text('Extend page to top'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(settingsApp());
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });

  testWidgets(
    'web scroll uses its bridge when native scrolling is unavailable',
    (tester) async {
      _setPhoneSize(tester);
      final platform = FakeWebViewPlatform(supportsNativeScroll: false);
      WebViewPlatform.instance = platform;
      await tester.pumpWidget(
        _TestApp(
          repositories: [
            RepositoryProvider<AiContentRepository>.value(
              value: _FakeAiContentRepository(),
            ),
            RepositoryProvider<ItemDetailRepository>.value(
              value: _FakeItemDetailRepository(storyUrl: 'https://example.com'),
            ),
          ],
          child: const ItemDetailPage(itemId: 1),
        ),
      );
      await tester.pump();
      await tester.pump();
      platform.navigation.onFinished('https://example.com');
      await tester.pumpAndSettle();
      expect(platform.controller.scripts, isNotEmpty);
      platform.controller.channel!.onMessageReceived(
        const JavaScriptMessage(message: '150'),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(HpCollapsibleHeader)).height, 0);
      platform.controller.channel!.onMessageReceived(
        const JavaScriptMessage(message: '0'),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Back').hitTestable(), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('UserProfilePage renders profile panels and refresh action', (
    tester,
  ) async {
    _setPhoneSize(tester);

    await tester.pumpWidget(
      _TestApp(
        repositories: [
          RepositoryProvider<ItemDetailRepository>.value(
            value: _FakeItemDetailRepository(),
          ),
        ],
        child: const UserProfilePage(userId: 'pg'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('pg'), findsWidgets);
    expect(find.text('KARMA'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Profile about text.'), findsOneWidget);

    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.text('SUBMITTED'), findsOneWidget);
  });

  testWidgets('profile refresh retains content and stops loading on failure', (
    tester,
  ) async {
    _setPhoneSize(tester);
    final repository = _FakeItemDetailRepository();
    await tester.pumpWidget(
      _TestApp(
        repositories: [
          RepositoryProvider<ItemDetailRepository>.value(value: repository),
        ],
        child: const UserProfilePage(userId: 'pg'),
      ),
    );
    await tester.pumpAndSettle();
    final pending = repository.userRequest = Completer<HnUser>();
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump();
    expect(find.text('Profile about text.'), findsOneWidget);
    expect(find.byType(HpLoadingView), findsNothing);
    expect(find.byType(HpActivityIndicator), findsOneWidget);
    pending.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Profile about text.'), findsOneWidget);
    expect(
      find.text('Could not refresh. Pull down to try again.'),
      findsOneWidget,
    );
    expect(find.byType(HpActivityIndicator), findsNothing);
  });

  testWidgets(
    'adds provider keys separately and activates provider plus model together',
    (tester) async {
      _setPhoneSize(tester);
      final repository = _FakeAiSettingsRepository(
        settings: AiSettings.defaultsFor(AiProviderId.openAiCompatible),
      );
      await tester.pumpWidget(
        _TestApp(
          repositories: [
            RepositoryProvider<AiSettingsRepository>.value(value: repository),
          ],
          child: const SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not selected'), findsOneWidget);
      expect(find.text('Provider'), findsNothing);
      expect(find.text('No keys added'), findsOneWidget);
      expect(find.text('Manage connections'), findsNothing);

      await tester.tap(find.text('Display'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paragraph pairs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Japanese'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Providers & keys'));
      await tester.pumpAndSettle();
      expect(find.text('0 saved keys'), findsOneWidget);
      for (final name in ['OpenAI', 'Anthropic', 'Gemini']) {
        await tester.tap(find.text('Add API key'));
        await tester.pumpAndSettle();
        expect(find.text('Choose key provider'), findsOneWidget);
        expect(find.text('API Trust'), findsNothing);
        for (final existing in [
          'OpenAI',
          'Anthropic',
          'Gemini',
        ].takeWhile((value) => value != name)) {
          expect(
            find.descendant(
              of: find.byType(BottomSheet),
              matching: find.text(existing),
            ),
            findsNothing,
          );
        }
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();
        expect(find.text('No API key saved'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField), '$name-secret');
        await tester.tap(find.text('Save API key'));
        await tester.pumpAndSettle();
      }
      expect(find.text('3 saved keys'), findsOneWidget);
      expect(find.text('Add API key'), findsNothing);
      expect(find.text('Saved · •••• cret'), findsNWidgets(3));
      expect(repository.settings.model, isEmpty);
      expect(repository.settings.providerId, AiProviderId.openAiCompatible);

      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      await tester.tap(find.text('Replace API key'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'discarded');
      await tester.tap(find.text('Cancel replacement'));
      await tester.pumpAndSettle();
      expect(
        await repository.readApiKey(AiProviderId.openAiCompatible),
        'OpenAI-secret',
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Not selected'), findsOneWidget);
      expect(find.text('3 keys saved'), findsOneWidget);

      await tester.tap(find.text('Active model'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      repository.modelsError = const AiException('Could not load models.');
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();
      expect(find.text('Could not load models.'), findsOneWidget);
      repository.modelsError = null;
      repository.models = [];
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No recommended lightweight models are available for this key.',
        ),
        findsOneWidget,
      );
      repository.models = ['gpt-5.6-luna'];
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('gpt-5.6-luna'));
      await tester.pumpAndSettle();
      expect(find.text('OpenAI · gpt-5.6-luna'), findsOneWidget);

      await tester.tap(find.text('Active model'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anthropic'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('OpenAI · gpt-5.6-luna'), findsOneWidget);
      expect(repository.settings.providerId, AiProviderId.openAiCompatible);

      repository.models = ['claude-haiku-4-5'];
      await tester.tap(find.text('Active model'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anthropic'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('claude-haiku-4-5'));
      await tester.pumpAndSettle();
      expect(find.text('Anthropic · claude-haiku-4-5'), findsOneWidget);
      expect(repository.settings.providerId, AiProviderId.anthropic);
      expect(repository.modelRequests.last, AiProviderId.anthropic);
      expect(repository.settings.targetLanguage, 'Japanese');
      expect(
        repository.settings.translationMode,
        AiTranslationMode.paragraphPairs,
      );

      await tester.tap(find.text('Providers & keys'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anthropic'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove API key'));
      await tester.pumpAndSettle();
      expect(find.text('2 saved keys'), findsOneWidget);
      expect(
        await repository.readApiKey(AiProviderId.openAiCompatible),
        'OpenAI-secret',
      );
      expect(await repository.readApiKey(AiProviderId.gemini), 'Gemini-secret');
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Not selected'), findsOneWidget);
      await tester.tap(find.text('Active model'));
      await tester.pumpAndSettle();
      expect(find.text('Anthropic'), findsNothing);
      expect(find.text('OpenAI'), findsOneWidget);
      expect(find.text('Gemini'), findsOneWidget);
    },
  );
}

void _setPhoneSize(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.repositories, required this.child});

  final List<RepositoryProvider<dynamic>> repositories;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: repositories,
      child: BlocProvider(
        create: (_) => ReadingPreferencesCubit()..load(),
        child: MaterialApp(
          theme: HpTheme.dark(),
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: child,
        ),
      ),
    );
  }
}

class _FakeItemsRepository implements ItemsRepository {
  _FakeItemsRepository({required this.items});

  final List<HnItem> items;
  final requestedTypes = <StoryType>[];
  Object? error;

  @override
  Future<List<HnItem>> fetchItems({
    StoryType storyType = StoryType.top,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    requestedTypes.add(storyType);
    if (error != null) throw error!;
    return items;
  }

  @override
  Future<List<HnItem>?> refreshVisibleItemsIfChanged({
    required StoryType storyType,
    required List<HnItem> currentItems,
    int limit = 20,
  }) async {
    return currentItems;
  }
}

class _FakeItemDetailRepository implements ItemDetailRepository {
  _FakeItemDetailRepository({this.storyUrl});

  final String? storyUrl;
  Completer<HnUser>? userRequest;

  @override
  Future<List<CommentNode>> fetchCommentsForStory(HnItem story) async {
    return [
      CommentNode(
        comment: const HnItem(
          id: 10,
          type: 'comment',
          time: 1,
          by: 'commenter',
          title: '',
          score: 0,
          descendants: 0,
          text: 'A useful comment',
        ),
        children: const [],
      ),
    ];
  }

  @override
  Future<HnItem> fetchStory(int itemId) async {
    return HnItem(
      id: 1,
      type: 'story',
      time: 1,
      by: 'pg',
      title: 'Self post title',
      score: 7,
      descendants: 1,
      url: storyUrl,
      text: 'Self post body with useful details.',
      kids: [10],
    );
  }

  @override
  Future<HnUser> fetchUser(String id) async {
    if (userRequest != null) return userRequest!.future;
    return HnUser(
      id: id,
      created: 1,
      karma: 42,
      about: 'Profile about text.',
      submitted: const [1, 2, 3],
    );
  }

  @override
  Future<HnItem> fetchUserPreviewItem(int id) => fetchStory(id);
}

class _FakeAiSettingsRepository implements AiSettingsRepository {
  @override
  Future<List<AiProviderDefinition>> loadProviders() async =>
      AiProviders.available;

  _FakeAiSettingsRepository({required this.settings});

  AiSettings settings;
  AiSettings? saved;
  String? apiKeyReplacement;
  Object? modelsError;
  List<String> models = ['gpt-5.6-luna', 'gpt-4.1-mini'];
  final modelRequests = <AiProviderId>[];
  final keys = <AiProviderId, String>{};
  final storedSettings = <AiProviderId, AiSettings>{};

  @override
  Future<List<String>> loadModels(AiProviderId providerId) async {
    modelRequests.add(providerId);
    if (modelsError != null) throw modelsError!;
    return models;
  }

  @override
  Future<void> saveApiKey(AiProviderId providerId, String apiKey) async {
    apiKeyReplacement = apiKey;
    keys[providerId] = apiKey;
    if (providerId == settings.providerId) {
      settings = settings.copyWith(hasApiKey: true);
    }
  }

  @override
  Future<void> clearApiKey(AiProviderId providerId) async {
    keys.remove(providerId);
    if (providerId == settings.providerId) {
      settings = settings.copyWith(hasApiKey: false);
    }
  }

  @override
  Future<AiSettings> load({AiProviderId? providerId}) async {
    final id = providerId ?? settings.providerId;
    final result = id == settings.providerId
        ? settings
        : storedSettings[id] ?? AiSettings.defaultsFor(id);
    return result.copyWith(hasApiKey: keys.containsKey(id));
  }

  @override
  Future<String?> readApiKey(AiProviderId providerId) async => keys[providerId];

  @override
  Future<void> save(AiSettings settings, {String? apiKeyReplacement}) async {
    saved = settings;
    this.apiKeyReplacement = apiKeyReplacement;
    this.settings = settings;
    storedSettings[settings.providerId] = settings;
  }
}

HnItem _story(int id) {
  return HnItem(
    id: id,
    type: 'story',
    time: 1,
    by: 'user$id',
    title: 'story $id',
    score: id * 10,
    descendants: id,
    url: 'https://example.com/story/$id',
  );
}

class _FakeAiContentRepository extends AiContentRepository {
  _FakeAiContentRepository({this.summary = 'Summary'})
    : super(
        settingsRepository: _FakeAiSettingsRepository(
          settings: AiSettings.defaultsFor(AiProviderId.openAiCompatible),
        ),
      );

  final String summary;
  final summarizedUrls = <String>[];

  @override
  Future<String> summarizeWebPageUrl(String url) async {
    summarizedUrls.add(url);
    return summary;
  }

  @override
  Future<String> translateComment(String rawCommentText) async {
    return 'Translated comment';
  }

  @override
  Future<AiTranslationMode> loadTranslationMode() async {
    return AiTranslationMode.replaceOriginal;
  }
}
