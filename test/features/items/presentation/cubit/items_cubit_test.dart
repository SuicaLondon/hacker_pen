import 'dart:async';

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

  test('refreshItems retains the feed until refreshed items arrive', () async {
    final repository = _FakeItemsRepository(items: [_story(1)]);
    final cubit = ItemsCubit(repository);
    addTearDown(cubit.close);
    await cubit.loadItems(storyType: StoryType.ask);
    final response = Completer<List<HnItem>>();
    repository.nextFetch = response.future;

    final refresh = cubit.refreshItems();

    expect(cubit.state.status, ItemsStatus.success);
    expect(cubit.state.items.single.id, 1);
    expect(repository.requestedTypes.last, StoryType.ask);
    expect(repository.forceRefreshRequests, [false, true]);

    response.complete([_story(2)]);
    await refresh;

    expect(cubit.state.status, ItemsStatus.success);
    expect(cubit.state.items.single.id, 2);
    expect(cubit.state.errorMessage, isNull);
  });

  test('refreshItems preserves stories after a failed refresh', () async {
    final repository = _FakeItemsRepository(items: [_story(1)]);
    final cubit = ItemsCubit(repository);
    addTearDown(cubit.close);
    await cubit.loadItems();
    final response = Completer<List<HnItem>>();
    repository.nextFetch = response.future;

    final refresh = cubit.refreshItems();
    response.completeError(StateError('offline'));
    await refresh;

    expect(cubit.state.status, ItemsStatus.success);
    expect(cubit.state.items.single.id, 1);
    expect(cubit.state.errorMessage, contains('offline'));

    repository.nextFetch = null;
    await cubit.refreshItems();
    expect(cubit.state.errorMessage, isNull);
  });

  test('a pending refresh cannot overwrite a newly selected tab', () async {
    final repository = _FakeItemsRepository(items: [_story(1)]);
    final cubit = ItemsCubit(repository);
    addTearDown(cubit.close);
    await cubit.loadItems();
    final response = Completer<List<HnItem>>();
    repository.nextFetch = response.future;
    final refresh = cubit.refreshItems();

    repository.nextFetch = Future.value([_story(3)]);
    await cubit.loadItems(storyType: StoryType.ask);
    response.complete([_story(2)]);
    await refresh;

    expect(cubit.state.storyType, StoryType.ask);
    expect(cubit.state.items.single.id, 3);
    expect(cubit.state.errorMessage, isNull);
  });

  test('duplicate refreshes and background sync do not overlap', () async {
    final repository = _FakeItemsRepository(items: [_story(1)]);
    final cubit = ItemsCubit(repository);
    addTearDown(cubit.close);
    await cubit.loadItems();
    final response = Completer<List<HnItem>>();
    repository.nextFetch = response.future;
    final refresh = cubit.refreshItems();

    await cubit.refreshItems();
    await cubit.syncWithUpdates();
    expect(repository.requestedTypes, hasLength(2));
    expect(repository.refreshCalls, 0);

    response.complete([_story(2)]);
    await refresh;
  });

  test('background sync cannot overwrite a later manual refresh', () async {
    final repository = _FakeItemsRepository(items: [_story(1)]);
    final cubit = ItemsCubit(repository);
    addTearDown(cubit.close);
    await cubit.loadItems();
    final syncResponse = Completer<List<HnItem>?>();
    repository.nextSync = syncResponse.future;
    final sync = cubit.syncWithUpdates();

    repository.nextFetch = Future.value([_story(3)]);
    await cubit.refreshItems();
    syncResponse.complete([_story(2)]);
    await sync;

    expect(cubit.state.items.single.id, 3);
  });

  test('closing during refresh safely ignores its completion', () async {
    final repository = _FakeItemsRepository(items: [_story(1)]);
    final cubit = ItemsCubit(repository);
    await cubit.loadItems();
    final response = Completer<List<HnItem>>();
    repository.nextFetch = response.future;
    final refresh = cubit.refreshItems();

    await cubit.close();
    response.complete([_story(2)]);
    await expectLater(refresh, completes);
    await expectLater(cubit.refreshItems(), completes);

    expect(cubit.state.items.single.id, 1);
    expect(repository.requestedTypes, hasLength(2));
  });
}

class _FakeItemsRepository implements ItemsRepository {
  _FakeItemsRepository({this.items = const [], this.refreshed, this.error});

  final List<HnItem> items;
  final List<HnItem>? refreshed;
  final Object? error;
  var refreshCalls = 0;
  final requestedTypes = <StoryType>[];
  final forceRefreshRequests = <bool>[];
  Future<List<HnItem>>? nextFetch;
  Future<List<HnItem>?>? nextSync;

  @override
  Future<List<HnItem>> fetchItems({
    StoryType storyType = StoryType.top,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    requestedTypes.add(storyType);
    forceRefreshRequests.add(forceRefresh);
    if (nextFetch != null) return nextFetch!;
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
    if (nextSync != null) return nextSync!;
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
