import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/hn_item.dart';
import '../../data/item_detail_repository.dart';
import 'item_detail_state.dart';

class ItemDetailCubit extends Cubit<ItemDetailState> {
  ItemDetailCubit(this._repository) : super(const ItemDetailState());

  final ItemDetailRepository _repository;

  Future<void> load(int itemId) async {
    emit(
      state.copyWith(
        requestedItemId: itemId,
        storyStatus: ItemDetailStoryStatus.loading,
        commentsStatus: ItemDetailCommentsStatus.initial,
        story: null,
        comments: const [],
        storyErrorMessage: null,
        commentsErrorMessage: null,
      ),
    );

    try {
      final story = await _repository.fetchStory(itemId);
      emit(
        state.copyWith(
          storyStatus: ItemDetailStoryStatus.success,
          story: story,
          commentsStatus: ItemDetailCommentsStatus.loading,
          comments: const [],
          commentsErrorMessage: null,
        ),
      );

      await _loadCommentsForStory(story);
    } catch (error) {
      emit(
        state.copyWith(
          storyStatus: ItemDetailStoryStatus.failure,
          storyErrorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> reloadComments() async {
    final story = state.story;
    if (story == null) {
      return;
    }

    emit(
      state.copyWith(
        commentsStatus: ItemDetailCommentsStatus.loading,
        commentsErrorMessage: null,
      ),
    );
    await _loadCommentsForStory(story);
  }

  Future<void> _loadCommentsForStory(HnItem story) async {
    try {
      final comments = await _repository.fetchCommentsForStory(story);
      emit(
        state.copyWith(
          commentsStatus: ItemDetailCommentsStatus.success,
          comments: comments,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          commentsStatus: ItemDetailCommentsStatus.failure,
          commentsErrorMessage: error.toString(),
        ),
      );
    }
  }
}
