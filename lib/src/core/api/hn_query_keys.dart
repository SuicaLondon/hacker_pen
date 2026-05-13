import '../domain/story_type.dart';

class HnQueryKeys {
  const HnQueryKeys._();

  static List<Object> item(int id) => ['hn', 'item', id];

  static List<Object> user(String id) => ['hn', 'user', id];

  static List<Object> storyIds(StoryType type) => ['hn', 'storyIds', type.name];

  static const List<Object> maxItemId = ['hn', 'maxItemId'];

  static const List<Object> updates = ['hn', 'updates'];
}
