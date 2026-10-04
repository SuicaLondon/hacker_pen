import 'dart:convert';

import 'package:cached_query/cached_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/api/api_client.dart';
import 'package:hacker_pen/src/core/api/hn_api_service.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/core/domain/story_type.dart';
import 'package:hacker_pen/src/features/items/data/items_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() => CachedQuery.instance.reset());

  test('fetchItems keeps only stories and respects limit', () async {
    final service = _FakeHnApiService();
    final repository = ItemsRepository(service);

    final items = await repository.fetchItems(limit: 3);

    expect(items.map((item) => item.id), [1, 3]);
    expect(service.loadedIds, [1, 2, 3]);
  });

  test(
    'forced fetch refreshes the story ids and previously cached items',
    () async {
      var refreshed = false;
      final requestedPaths = <String>[];
      final repository = ItemsRepository(
        HnApiService(
          apiClient: ApiClient(
            baseUrl: 'https://example.test/',
            httpClient: MockClient((request) async {
              final path = request.url.path;
              requestedPaths.add(path);
              if (path == '/newstories.json') {
                return http.Response(refreshed ? '[2,1]' : '[1]', 200);
              }
              final id = path == '/item/1.json' ? 1 : 2;
              return http.Response(
                jsonEncode({
                  'id': id,
                  'type': 'story',
                  'time': 1,
                  'by': 'user$id',
                  'title': 'item $id',
                  'score': refreshed ? 100 : 1,
                  'descendants': 0,
                }),
                200,
              );
            }),
          ),
        ),
      );

      final initial = await repository.fetchItems(
        storyType: StoryType.newStories,
      );
      expect(initial.single.score, 1);
      refreshed = true;

      final cached = await repository.fetchItems(
        storyType: StoryType.newStories,
      );
      expect(cached.single.score, 1);
      expect(requestedPaths, ['/newstories.json', '/item/1.json']);

      final fresh = await repository.fetchItems(
        storyType: StoryType.newStories,
        forceRefresh: true,
      );
      expect(fresh.map((item) => item.id), [2, 1]);
      expect(fresh.map((item) => item.score), [100, 100]);
      expect(requestedPaths, [
        '/newstories.json',
        '/item/1.json',
        '/newstories.json',
        '/item/2.json',
        '/item/1.json',
      ]);
    },
  );

  test('story type metadata exposes labels and endpoints', () {
    expect(StoryType.top.label, 'Top');
    expect(StoryType.newStories.endpointPath, '/newstories.json');
    expect(StoryType.best.label, 'Best');
    expect(StoryType.ask.endpointPath, '/askstories.json');
    expect(StoryType.show.label, 'Show');
  });
}

class _FakeHnApiService extends HnApiService {
  _FakeHnApiService();

  final loadedIds = <int>[];

  @override
  Future<List<int>> getStoryIdsByType(
    StoryType type, {
    bool forceRefresh = false,
  }) async => [1, 2, 3, 4];

  @override
  Future<HnItem> getItem(int id, {bool forceRefresh = false}) async {
    loadedIds.add(id);
    return HnItem(
      id: id,
      type: id == 2 ? 'comment' : 'story',
      time: 1,
      by: 'user$id',
      title: 'item $id',
      score: id,
      descendants: id,
    );
  }
}
