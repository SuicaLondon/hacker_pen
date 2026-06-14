import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/api/models/hn_user.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/features/item_detail/data/item_detail_repository.dart';
import 'package:hacker_pen/src/features/item_detail/domain/comment_node.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/cubit/item_detail_cubit.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/cubit/item_detail_state.dart';

void main() {
  test('load emits story and comments success states', () async {
    final cubit = ItemDetailCubit(_FakeItemDetailRepository());

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<ItemDetailState>().having(
          (state) => state.storyStatus,
          'story status',
          ItemDetailStoryStatus.loading,
        ),
        isA<ItemDetailState>()
            .having(
              (state) => state.storyStatus,
              'story status',
              ItemDetailStoryStatus.success,
            )
            .having(
              (state) => state.commentsStatus,
              'comments status',
              ItemDetailCommentsStatus.loading,
            ),
        isA<ItemDetailState>()
            .having(
              (state) => state.commentsStatus,
              'comments status',
              ItemDetailCommentsStatus.success,
            )
            .having((state) => state.comments.single.comment.id, 'comment', 2),
      ]),
    );

    await cubit.load(1);
    await expectation;
  });

  test('load and reload expose failure states', () async {
    final repository = _FakeItemDetailRepository();
    final cubit = ItemDetailCubit(repository);

    repository.storyError = StateError('story failed');
    await cubit.load(1);
    expect(cubit.state.storyStatus, ItemDetailStoryStatus.failure);
    expect(cubit.state.storyErrorMessage, contains('story failed'));

    repository.storyError = null;
    repository.commentsError = StateError('comments failed');
    await cubit.load(1);
    expect(cubit.state.commentsStatus, ItemDetailCommentsStatus.failure);

    repository.commentsError = null;
    await cubit.reloadComments();
    expect(cubit.state.commentsStatus, ItemDetailCommentsStatus.success);
  });
}

class _FakeItemDetailRepository implements ItemDetailRepository {
  Object? storyError;
  Object? commentsError;

  @override
  Future<List<CommentNode>> fetchCommentsForStory(HnItem story) async {
    if (commentsError != null) throw commentsError!;
    return [CommentNode(comment: _comment(2), children: const [])];
  }

  @override
  Future<HnItem> fetchStory(int itemId) async {
    if (storyError != null) throw storyError!;
    return HnItem(
      id: itemId,
      type: 'story',
      time: 1,
      by: 'pg',
      title: 'story',
      score: 1,
      descendants: 1,
    );
  }

  @override
  Future<HnUser> fetchUser(String id) async {
    return HnUser(id: id, created: 1, karma: 1);
  }

  @override
  Future<HnItem> fetchUserPreviewItem(int id) => fetchStory(id);
}

HnItem _comment(int id) {
  return HnItem(
    id: id,
    type: 'comment',
    time: 1,
    by: 'commenter',
    title: '',
    score: 0,
    descendants: 0,
    text: 'comment',
  );
}
