import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/api/hn_api_service.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/core/domain/story_type.dart';
import 'package:hacker_pen/src/features/items/data/items_repository.dart';

void main() {
  test('fetchItems keeps only stories and respects limit', () async {
    final service = _FakeHnApiService();
    final repository = ItemsRepository(service);

    final items = await repository.fetchItems(limit: 3);

    expect(items.map((item) => item.id), [1, 3]);
    expect(service.loadedIds, [1, 2, 3]);
  });

  test('story type metadata exposes labels and endpoints', () {
    expect(StoryTypeMetadata.homeTabs, contains(StoryType.job));
    expect(StoryType.top.label, 'Top');
    expect(StoryType.newStories.endpointPath, '/newstories.json');
    expect(StoryType.best.label, 'Best');
    expect(StoryType.ask.endpointPath, '/askstories.json');
    expect(StoryType.show.label, 'Show');
    expect(StoryType.job.endpointPath, '/jobstories.json');
  });
}

class _FakeHnApiService extends HnApiService {
  _FakeHnApiService();

  final loadedIds = <int>[];

  @override
  Future<List<int>> getStoryIdsByType(StoryType type) async => [1, 2, 3, 4];

  @override
  Future<HnItem> getItem(int id) async {
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
