import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/hn_item.dart';
import '../domain/story_type.dart';
import 'hn_api_exception.dart';
import 'models/hn_updates.dart';
import 'models/hn_user.dart';

class HnApiService {
  HnApiService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static const String _baseUrl = 'https://hacker-news.firebaseio.com/v0';
  final http.Client _httpClient;

  Future<HnItem> getItem(int id) async {
    final json = await _getJsonMap('/item/$id.json');
    return HnItem.fromJson(json);
  }

  Future<HnUser> getUser(String id) async {
    final json = await _getJsonMap('/user/$id.json');
    return HnUser.fromJson(json);
  }

  Future<int> getMaxItemId() async {
    return _getJsonInt('/maxitem.json');
  }

  Future<List<int>> getTopStories() => _getJsonIntList('/topstories.json');

  Future<List<int>> getNewStories() => _getJsonIntList('/newstories.json');

  Future<List<int>> getBestStories() => _getJsonIntList('/beststories.json');

  Future<List<int>> getAskStories() => _getJsonIntList('/askstories.json');

  Future<List<int>> getShowStories() => _getJsonIntList('/showstories.json');

  Future<List<int>> getJobStories() => _getJsonIntList('/jobstories.json');

  Future<HnUpdates> getUpdates() async {
    final json = await _getJsonMap('/updates.json');
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

  Future<Map<String, dynamic>> _getJsonMap(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient.get(uri);

    if (response.statusCode != 200) {
      throw HnApiException(
        'Request failed for $path',
        statusCode: response.statusCode,
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw HnApiException('Unexpected map response for $path');
    }

    return decoded;
  }

  Future<List<int>> _getJsonIntList(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient.get(uri);

    if (response.statusCode != 200) {
      throw HnApiException(
        'Request failed for $path',
        statusCode: response.statusCode,
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw HnApiException('Unexpected list response for $path');
    }

    return decoded.whereType<int>().toList(growable: false);
  }

  Future<int> _getJsonInt(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient.get(uri);

    if (response.statusCode != 200) {
      throw HnApiException(
        'Request failed for $path',
        statusCode: response.statusCode,
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! int) {
      throw HnApiException('Unexpected int response for $path');
    }

    return decoded;
  }
}
