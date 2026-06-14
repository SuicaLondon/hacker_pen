import 'package:cached_query/cached_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/api/api_exception.dart';
import 'package:hacker_pen/src/core/api/hn_api_service.dart';
import 'package:hacker_pen/src/core/api/models/hn_updates.dart';
import 'package:hacker_pen/src/core/domain/story_type.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hacker_pen/src/core/api/api_client.dart';

void main() {
  setUp(() => CachedQuery.instance.reset());

  test('parses item, user, max id, updates, and story ids', () async {
    final service = HnApiService(
      apiClient: ApiClient(
        baseUrl: 'https://example.test/v0/',
        httpClient: MockClient((request) async {
          return http.Response(_responseFor(request.url.path), 200);
        }),
      ),
    );

    expect((await service.getItem(1)).title, 'A story');
    expect((await service.getUser('pg')).karma, 123);
    expect(await service.getMaxItemId(), 999);
    expect(
      await service.getUpdates(),
      const HnUpdates(items: [1], profiles: ['pg']),
    );
    expect(await service.getStoryIdsByType(StoryType.top), [1, 2]);
    expect(await service.getStoryIdsByType(StoryType.newStories), [3]);
    expect(await service.getStoryIdsByType(StoryType.best), [4]);
    expect(await service.getStoryIdsByType(StoryType.ask), [5]);
    expect(await service.getStoryIdsByType(StoryType.show), [6]);
    expect(await service.getStoryIdsByType(StoryType.job), [7]);
  });

  test(
    'throws descriptive exceptions for unexpected response shapes',
    () async {
      final service = HnApiService(
        apiClient: ApiClient(
          baseUrl: 'https://example.test/v0/',
          httpClient: MockClient((_) async => http.Response('"bad"', 200)),
        ),
      );

      await expectLater(service.getItem(1), throwsA(isA<ApiException>()));
      await expectLater(service.getTopStories(), throwsA(isA<ApiException>()));
      await expectLater(service.getMaxItemId(), throwsA(isA<ApiException>()));
    },
  );
}

String _responseFor(String path) {
  return switch (path) {
    '/v0/item/1.json' =>
      '{"id":1,"type":"story","time":1,"by":"pg","title":"A story","score":5,"descendants":2,"kids":[10]}',
    '/v0/user/pg.json' =>
      '{"id":"pg","created":1,"karma":123,"about":"hello","submitted":[1,"bad"]}',
    '/v0/maxitem.json' => '999',
    '/v0/updates.json' => '{"items":[1,"bad"],"profiles":["pg",2]}',
    '/v0/topstories.json' => '[1,2]',
    '/v0/newstories.json' => '[3]',
    '/v0/beststories.json' => '[4]',
    '/v0/askstories.json' => '[5]',
    '/v0/showstories.json' => '[6]',
    '/v0/jobstories.json' => '[7]',
    _ => 'null',
  };
}
