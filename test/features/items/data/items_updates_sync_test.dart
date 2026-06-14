import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/api/hn_api_service.dart';
import 'package:hacker_pen/src/core/api/models/hn_updates.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/core/domain/story_type.dart';
import 'package:hacker_pen/src/features/items/data/items_updates_sync.dart';

void main() {
  test('fetches full list when current items are empty', () async {
    final service = _FakeHnApiService();
    final sync = ItemsUpdatesSync(service);

    final items = await sync.refreshVisibleItemsIfChanged(
      storyType: StoryType.top,
      currentItems: const [],
      limit: 3,
    );

    expect(items!.map((item) => item.id), [1, 3]);
  });

  test('returns null when no visible items changed', () async {
    final sync = ItemsUpdatesSync(
      _FakeHnApiService(
        updates: const HnUpdates(items: [9], profiles: []),
      ),
    );

    final items = await sync.refreshVisibleItemsIfChanged(
      storyType: StoryType.top,
      currentItems: [_story(1)],
    );

    expect(items, isNull);
  });

  test('refreshes changed visible items', () async {
    final sync = ItemsUpdatesSync(_FakeHnApiService());

    final items = await sync.refreshVisibleItemsIfChanged(
      storyType: StoryType.top,
      currentItems: [_story(1), _story(3)],
    );

    expect(items!.map((item) => item.score), [100, 3]);
  });
}

class _FakeHnApiService extends HnApiService {
  _FakeHnApiService({this.updates = const HnUpdates(items: [1], profiles: [])});

  final HnUpdates updates;

  @override
  Future<List<int>> getStoryIdsByType(StoryType type) async => [1, 2, 3];

  @override
  Future<HnItem> getItem(int id) async {
    return _story(
      id,
      score: id == 1 ? 100 : id,
      type: id == 2 ? 'comment' : 'story',
    );
  }

  @override
  Future<HnUpdates> getUpdates() async => updates;
}

HnItem _story(int id, {int? score, String type = 'story'}) {
  return HnItem(
    id: id,
    type: type,
    time: 1,
    by: 'user$id',
    title: 'story $id',
    score: score ?? id,
    descendants: id,
  );
}
