import '../../../core/api/hn_api_service.dart';
import '../../../core/domain/hn_item.dart';
import '../../../core/domain/story_type.dart';

class ItemsUpdatesSync {
  ItemsUpdatesSync(this._apiService);

  final HnApiService _apiService;

  /// Uses updates.json as an incremental signal.
  /// If none of the visible item ids changed, returns null to skip UI refresh.
  Future<List<HnItem>?> refreshVisibleItemsIfChanged({
    required StoryType storyType,
    required List<HnItem> currentItems,
    int limit = 20,
  }) async {
    if (currentItems.isEmpty) {
      return _fetchFull(storyType: storyType, limit: limit);
    }

    final updates = await _apiService.getUpdates();
    final currentIds = currentItems.map((item) => item.id).toSet();
    final changedVisible = updates.items.any(currentIds.contains);

    if (!changedVisible) {
      return null;
    }

    final itemsById = {for (final item in currentItems) item.id: item};
    final changedIds = updates.items.where(currentIds.contains);

    final refreshed = await Future.wait(changedIds.map(_apiService.getItem));
    for (final item in refreshed) {
      itemsById[item.id] = item;
    }

    return currentItems
        .map((item) => itemsById[item.id] ?? item)
        .where((item) => item.isStory)
        .toList(growable: false);
  }

  Future<List<HnItem>> _fetchFull({
    required StoryType storyType,
    required int limit,
  }) async {
    final ids = await _apiService.getStoryIdsByType(storyType);
    final targetIds = ids.take(limit);
    final items = await Future.wait(targetIds.map(_apiService.getItem));
    return items.where((item) => item.isStory).toList(growable: false);
  }
}
