import '../../../core/api/hn_api_service.dart';
import '../../../core/api/models/hn_user.dart';
import '../../../core/domain/hn_item.dart';
import '../domain/comment_node.dart';

class ItemDetailRepository {
  ItemDetailRepository(this._apiService);

  final HnApiService _apiService;

  Future<HnItem> fetchStory(int itemId) => _apiService.getItem(itemId);

  Future<List<CommentNode>> fetchCommentsForStory(HnItem story) {
    return _loadCommentTree(story.kids);
  }

  Future<List<CommentNode>> _loadCommentTree(List<int> ids) async {
    final futures = ids.map((id) async {
      final item = await _apiService.getItem(id);
      if (!item.isComment || item.deleted || item.dead) {
        return null;
      }

      final children = await _loadCommentTree(item.kids);
      return CommentNode(comment: item, children: children);
    });

    final nodes = await Future.wait(futures);
    return nodes.whereType<CommentNode>().toList(growable: false);
  }

  Future<HnItem> fetchUserPreviewItem(int id) => _apiService.getItem(id);

  Future<HnUser> fetchUser(String id) => _apiService.getUser(id);
}
