import '../../../core/api/hn_api_service.dart';
import '../../../core/domain/hn_item.dart';
import '../../../core/domain/story_type.dart';
import 'items_updates_sync.dart';

class ItemsRepository {
  ItemsRepository(this._apiService) : _updatesSync = ItemsUpdatesSync(_apiService);

  final HnApiService _apiService;
  final ItemsUpdatesSync _updatesSync;

  Future<List<HnItem>> fetchItems({
    StoryType storyType = StoryType.top,
    int limit = 20,
  }) async {
    final ids = await _apiService.getStoryIdsByType(storyType);
    final targetIds = ids.take(limit);

    final futures = targetIds.map(_apiService.getItem);
    final items = await Future.wait(futures);

    return items.where((item) => item.isStory).toList(growable: false);
  }

  Future<List<HnItem>?> refreshVisibleItemsIfChanged({
    required StoryType storyType,
    required List<HnItem> currentItems,
    int limit = 20,
  }) {
    return _updatesSync.refreshVisibleItemsIfChanged(
      storyType: storyType,
      currentItems: currentItems,
      limit: limit,
    );
  }
}
