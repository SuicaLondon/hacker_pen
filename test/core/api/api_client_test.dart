import 'package:cached_query/cached_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/api/api_client.dart';
import 'package:hacker_pen/src/core/api/api_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() => CachedQuery.instance.reset());

  test('preserves the base path when request paths start with slash', () async {
    late Uri requestedUri;
    final client = ApiClient(
      baseUrl: 'https://hacker-news.firebaseio.com/v0/',
      httpClient: MockClient((request) async {
        requestedUri = request.url;
        return http.Response('[1,2,3]', 200);
      }),
    );

    final data = await client.getJson<List<int>>(
      queryKey: ['test', 'storyIds'],
      path: '/topstories.json',
      decode: (json) => (json as List<dynamic>).whereType<int>().toList(),
    );

    expect(data, [1, 2, 3]);
    expect(
      requestedUri,
      Uri.parse('https://hacker-news.firebaseio.com/v0/topstories.json'),
    );
  });

  test('uses fresh cached data until a request forces a refresh', () async {
    var requests = 0;
    final client = ApiClient(
      baseUrl: 'https://example.test/',
      httpClient: MockClient((request) async {
        requests += 1;
        return http.Response('$requests', 200);
      }),
    );

    Future<int> fetch({bool forceRefresh = false}) => client.getJson<int>(
      queryKey: ['test', 'cached'],
      path: '/value.json',
      decode: (json) => json as int,
      forceRefresh: forceRefresh,
    );

    expect(await fetch(), 1);
    expect(await fetch(), 1);
    expect(requests, 1);
    expect(await fetch(forceRefresh: true), 2);
    expect(await fetch(), 2);
    expect(requests, 2);
  });

  test('surfaces a forced refresh failure even when data is cached', () async {
    var requests = 0;
    final client = ApiClient(
      baseUrl: 'https://example.test/',
      httpClient: MockClient((request) async {
        requests += 1;
        return requests == 1
            ? http.Response('1', 200)
            : http.Response('Unavailable', 503);
      }),
    );

    Future<int> fetch({bool forceRefresh = false}) => client.getJson<int>(
      queryKey: ['test', 'failedRefresh'],
      path: '/value.json',
      decode: (json) => json as int,
      forceRefresh: forceRefresh,
    );

    expect(await fetch(), 1);
    await expectLater(
      fetch(forceRefresh: true),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          503,
        ),
      ),
    );
    expect(requests, 2);
  });
}
