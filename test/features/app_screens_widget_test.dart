import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/ai/ai_provider.dart';
import 'package:hacker_pen/src/core/ai/ai_settings.dart';
import 'package:hacker_pen/src/core/ai/ai_settings_repository.dart';
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
import 'package:hacker_pen/src/features/items/presentation/cubit/items_cubit.dart';
import 'package:hacker_pen/src/features/items/presentation/views/items_page.dart';
import 'package:hacker_pen/src/features/settings/presentation/views/settings_page.dart';

void main() {
  testWidgets('ItemsPage renders success feed, tabs, and error state', (
    tester,
  ) async {
    final repository = _FakeItemsRepository(items: [_story(1), _story(2)]);

    await tester.pumpWidget(
      _TestApp(
        repositories: [
          RepositoryProvider<ItemsRepository>.value(value: repository),
        ],
        child: BlocProvider(
          create: (_) => ItemsCubit(repository)..loadItems(),
          child: const ItemsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HackerPen'), findsOneWidget);
    expect(find.text('story 1'), findsOneWidget);
    expect(find.text('Top'), findsOneWidget);

    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
    expect(repository.requestedTypes, contains(StoryType.ask));

    repository.error = StateError('offline');
    await tester.tap(find.text('Jobs'));
    await tester.pumpAndSettle();
    expect(find.text('Failed to load items'), findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);
  });

  testWidgets('ItemDetailPage renders self post and opens comments sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        repositories: [
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
    expect(find.text('1 comments'), findsOneWidget);

    await tester.tap(find.text('1 comments'));
    await tester.pumpAndSettle();

    expect(find.text('Comments 1'), findsOneWidget);
    expect(find.text('commenter'), findsOneWidget);
    expect(find.text('A useful comment'), findsOneWidget);
  });

  testWidgets('UserProfilePage renders profile panels and refresh action', (
    tester,
  ) async {
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
    expect(find.text('Karma'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Profile about text.'), findsOneWidget);

    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.text('Submitted'), findsOneWidget);
  });

  testWidgets('SettingsPage renders provider form and saves settings', (
    tester,
  ) async {
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

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('AI Provider'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'secret');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.saved?.hasApiKey, isFalse);
    expect(repository.apiKeyReplacement, 'secret');
    expect(find.text('Saved.'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.repositories, required this.child});

  final List<RepositoryProvider<dynamic>> repositories;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: repositories,
      child: MaterialApp(
        theme: HpTheme.light(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: child,
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
    return const HnItem(
      id: 1,
      type: 'story',
      time: 1,
      by: 'pg',
      title: 'Self post title',
      score: 7,
      descendants: 1,
      text: 'Self post body with useful details.',
      kids: [10],
    );
  }

  @override
  Future<HnUser> fetchUser(String id) async {
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
  _FakeAiSettingsRepository({required this.settings});

  AiSettings settings;
  AiSettings? saved;
  String? apiKeyReplacement;

  @override
  Future<void> clearApiKey(AiProviderId providerId) async {
    settings = settings.copyWith(hasApiKey: false);
  }

  @override
  Future<AiSettings> load({AiProviderId? providerId}) async {
    return settings.copyWith(providerId: providerId);
  }

  @override
  Future<String?> readApiKey(AiProviderId providerId) async => null;

  @override
  Future<void> save(AiSettings settings, {String? apiKeyReplacement}) async {
    saved = settings;
    this.apiKeyReplacement = apiKeyReplacement;
    this.settings = settings.copyWith(hasApiKey: true);
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
