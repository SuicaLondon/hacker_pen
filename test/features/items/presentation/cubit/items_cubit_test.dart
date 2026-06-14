import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/core/domain/story_type.dart';
import 'package:hacker_pen/src/features/items/data/items_repository.dart';
import 'package:hacker_pen/src/features/items/presentation/cubit/items_cubit.dart';
import 'package:hacker_pen/src/features/items/presentation/cubit/items_state.dart';

void main() {
  test('loadItems emits loading then success', () async {
    final cubit = ItemsCubit(_FakeItemsRepository(items: [_story(1)]));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<ItemsState>()
            .having((state) => state.status, 'status', ItemsStatus.loading)
            .having((state) => state.storyType, 'storyType', StoryType.ask),
        isA<ItemsState>()
            .having((state) => state.status, 'status', ItemsStatus.success)
            .having((state) => state.items.single.id, 'item id', 1),
      ]),
    );

    await cubit.loadItems(storyType: StoryType.ask);
    await expectation;
  });

  test('loadItems emits failure message', () async {
    final cubit = ItemsCubit(_FakeItemsRepository(error: StateError('nope')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<ItemsState>().having(
          (state) => state.status,
          'status',
          ItemsStatus.loading,
        ),
        isA<ItemsState>()
            .having((state) => state.status, 'status', ItemsStatus.failure)
            .having((state) => state.errorMessage, 'message', contains('nope')),
      ]),
    );

    await cubit.loadItems();
    await expectation;
  });

  test('syncWithUpdates refreshes only successful states', () async {
    final repository = _FakeItemsRepository(
      items: [_story(1)],
      refreshed: [_story(2)],
    );
    final cubit = ItemsCubit(repository);

    await cubit.syncWithUpdates();
    expect(repository.refreshCalls, 0);

    await cubit.loadItems();
    await cubit.syncWithUpdates();

    expect(repository.refreshCalls, 1);
    expect(cubit.state.items.single.id, 2);
  });
}

class _FakeItemsRepository implements ItemsRepository {
  _FakeItemsRepository({this.items = const [], this.refreshed, this.error});

  final List<HnItem> items;
  final List<HnItem>? refreshed;
  final Object? error;
  var refreshCalls = 0;

  @override
  Future<List<HnItem>> fetchItems({
    StoryType storyType = StoryType.top,
    int limit = 20,
  }) async {
    if (error != null) throw error!;
    return items;
  }

  @override
  Future<List<HnItem>?> refreshVisibleItemsIfChanged({
    required StoryType storyType,
    required List<HnItem> currentItems,
    int limit = 20,
  }) async {
    refreshCalls += 1;
    return refreshed;
  }
}

HnItem _story(int id) {
  return HnItem(
    id: id,
    type: 'story',
    time: 1,
    by: 'user$id',
    title: 'story $id',
    score: id,
    descendants: id,
  );
}
