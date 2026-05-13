import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/api/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
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
}
