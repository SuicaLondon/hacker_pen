import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/api/hn_api_service.dart';
import 'package:hacker_pen/src/core/api/models/hn_user.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/features/item_detail/data/item_detail_repository.dart';

void main() {
  test('loads comment tree and filters deleted or non-comment items', () async {
    final service = _FakeHnApiService();
    final repository = ItemDetailRepository(service);

    final story = await repository.fetchStory(1);
    final comments = await repository.fetchCommentsForStory(story);
    final user = await repository.fetchUser('pg');
    final preview = await repository.fetchUserPreviewItem(10);

    expect(story.kids, [10, 11, 12]);
    expect(comments, hasLength(1));
    expect(comments.single.comment.id, 10);
    expect(comments.single.children.single.comment.id, 13);
    expect(user.id, 'pg');
    expect(preview.id, 10);
  });
}

class _FakeHnApiService extends HnApiService {
  @override
  Future<HnItem> getItem(int id) async {
    return switch (id) {
      1 => const HnItem(
        id: 1,
        type: 'story',
        time: 1,
        by: 'pg',
        title: 'story',
        score: 1,
        descendants: 1,
        kids: [10, 11, 12],
      ),
      10 => const HnItem(
        id: 10,
        type: 'comment',
        time: 1,
        by: 'commenter',
        title: '',
        score: 0,
        descendants: 0,
        text: 'visible',
        kids: [13],
      ),
      11 => const HnItem(
        id: 11,
        type: 'comment',
        time: 1,
        by: 'deleted',
        title: '',
        score: 0,
        descendants: 0,
        deleted: true,
      ),
      12 => const HnItem(
        id: 12,
        type: 'story',
        time: 1,
        by: 'story',
        title: 'not a comment',
        score: 0,
        descendants: 0,
      ),
      13 => const HnItem(
        id: 13,
        type: 'comment',
        time: 1,
        by: 'child',
        title: '',
        score: 0,
        descendants: 0,
        text: 'child',
      ),
      _ => throw StateError('missing $id'),
    };
  }

  @override
  Future<HnUser> getUser(String id) async {
    return HnUser(id: id, created: 1, karma: 1);
  }
}
