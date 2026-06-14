import '../domain/hn_item.dart';
import '../domain/story_type.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'hn_query_keys.dart';
import 'models/hn_updates.dart';
import 'models/hn_user.dart';

class HnApiService {
  HnApiService({ApiClient? apiClient})
    : _apiClient =
          apiClient ??
          ApiClient(baseUrl: 'https://hacker-news.firebaseio.com/v0/');

  final ApiClient _apiClient;

  Future<HnItem> getItem(int id) async {
    final json = await _apiClient.getJson<Map<String, dynamic>>(
      queryKey: HnQueryKeys.item(id),
      path: '/item/$id.json',
      decode: _decodeMap('/item/$id.json'),
    );
    return HnItem.fromJson(json);
  }

  Future<HnUser> getUser(String id) async {
    final json = await _apiClient.getJson<Map<String, dynamic>>(
      queryKey: HnQueryKeys.user(id),
      path: '/user/$id.json',
      decode: _decodeMap('/user/$id.json'),
    );
    return HnUser.fromJson(json);
  }

  Future<int> getMaxItemId() async {
    return _apiClient.getJson<int>(
      queryKey: HnQueryKeys.maxItemId,
      path: '/maxitem.json',
      decode: _decodeInt('/maxitem.json'),
    );
  }

  Future<List<int>> getTopStories() => _getStoryIds(type: StoryType.top);

  Future<List<int>> getNewStories() => _getStoryIds(type: StoryType.newStories);

  Future<List<int>> getBestStories() => _getStoryIds(type: StoryType.best);

  Future<List<int>> getAskStories() => _getStoryIds(type: StoryType.ask);

  Future<List<int>> getShowStories() => _getStoryIds(type: StoryType.show);

  Future<List<int>> getJobStories() => _getStoryIds(type: StoryType.job);

  Future<HnUpdates> getUpdates() async {
    final json = await _apiClient.getJson<Map<String, dynamic>>(
      queryKey: HnQueryKeys.updates,
      path: '/updates.json',
      decode: _decodeMap('/updates.json'),
    );
    return HnUpdates.fromJson(json);
  }

  Future<List<int>> getStoryIdsByType(StoryType type) {
    switch (type) {
      case StoryType.top:
        return getTopStories();
      case StoryType.newStories:
        return getNewStories();
      case StoryType.best:
        return getBestStories();
      case StoryType.ask:
        return getAskStories();
      case StoryType.show:
        return getShowStories();
      case StoryType.job:
        return getJobStories();
    }
  }

  Future<List<int>> _getStoryIds({required StoryType type}) {
    final path = type.endpointPath;
    return _apiClient.getJson<List<int>>(
      queryKey: HnQueryKeys.storyIds(type),
      path: path,
      decode: _decodeIntList(path),
    );
  }

  Map<String, dynamic> Function(dynamic json) _decodeMap(String path) {
    return (json) {
      if (json is! Map<String, dynamic>) {
        throw ApiException('Unexpected map response for $path');
      }

      return json;
    };
  }

  List<int> Function(dynamic json) _decodeIntList(String path) {
    return (json) {
      if (json is! List<dynamic>) {
        throw ApiException('Unexpected list response for $path');
      }

      return json.whereType<int>().toList(growable: false);
    };
  }

  int Function(dynamic json) _decodeInt(String path) {
    return (json) {
      if (json is! int) {
        throw ApiException('Unexpected int response for $path');
      }

      return json;
    };
  }
}
