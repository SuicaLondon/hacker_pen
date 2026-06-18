import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ai/ai_content_repository.dart';
import '../../../../core/ai/ai_exception.dart';
import '../../../../core/domain/hn_item.dart';
import '../../../../core/utils/text_sanitizer.dart';
import '../../data/item_detail_repository.dart';
import '../../domain/comment_node.dart';
import 'item_detail_state.dart';

class ItemDetailCubit extends Cubit<ItemDetailState> {
  ItemDetailCubit(this._repository, this._aiContentRepository)
    : super(const ItemDetailState());

  final ItemDetailRepository _repository;
  final AiContentRepository _aiContentRepository;

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
        summaryStatus: ItemDetailAiStatus.idle,
        summaryText: null,
        summaryErrorMessage: null,
        commentTranslations: const {},
        threadTranslationLoadingIds: const {},
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
        commentTranslations: const {},
        threadTranslationLoadingIds: const {},
      ),
    );
    await _loadCommentsForStory(story);
  }

  Future<void> summarizeStory() async {
    final storyUrl = state.story?.url;
    if (storyUrl == null || storyUrl.isEmpty) {
      emit(
        state.copyWith(
          summaryStatus: ItemDetailAiStatus.failure,
          summaryErrorMessage: 'Only stories with a URL can be summarized.',
        ),
      );
      return;
    }

    if (state.summaryStatus == ItemDetailAiStatus.loading) {
      return;
    }

    emit(
      state.copyWith(
        summaryStatus: ItemDetailAiStatus.loading,
        summaryErrorMessage: null,
      ),
    );

    try {
      final summary = await _aiContentRepository.summarizeWebPageUrl(storyUrl);
      emit(
        state.copyWith(
          summaryStatus: ItemDetailAiStatus.success,
          summaryText: summary,
          summaryErrorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          summaryStatus: ItemDetailAiStatus.failure,
          summaryErrorMessage: _errorMessage(error),
        ),
      );
    }
  }

  Future<void> translateComment(HnItem comment) async {
    final current = state.commentTranslations[comment.id];
    final mode = await _aiContentRepository.loadTranslationMode();
    if (current?.status == ItemDetailAiStatus.loading) {
      return;
    }
    if (current?.status == ItemDetailAiStatus.success &&
        current?.mode == mode) {
      _setCommentTranslation(
        comment.id,
        current!.copyWith(showOriginal: !current.showOriginal),
      );
      return;
    }

    _setCommentTranslation(
      comment.id,
      const CommentTranslationState(
        status: ItemDetailAiStatus.loading,
        showOriginal: true,
      ),
    );

    try {
      final translation = await _aiContentRepository.translateComment(
        comment.text ?? '',
      );
      _setCommentTranslation(
        comment.id,
        CommentTranslationState(
          status: ItemDetailAiStatus.success,
          text: translation,
          showOriginal: false,
          mode: mode,
        ),
      );
    } catch (error) {
      _setCommentTranslation(
        comment.id,
        CommentTranslationState(
          status: ItemDetailAiStatus.failure,
          errorMessage: _errorMessage(error),
        ),
      );
    }
  }

  Future<void> translateCommentChildren(CommentNode node) async {
    if (node.children.isEmpty ||
        state.threadTranslationLoadingIds.contains(node.comment.id)) {
      return;
    }

    emit(
      state.copyWith(
        threadTranslationLoadingIds: {
          ...state.threadTranslationLoadingIds,
          node.comment.id,
        },
      ),
    );

    final descendants = <HnItem>[
      for (final child in node.children) ..._flattenComments(child),
    ];
    final mode = await _aiContentRepository.loadTranslationMode();

    await Future.wait(
      descendants
          .where((comment) {
            final translation = state.commentTranslations[comment.id];
            return translation?.status != ItemDetailAiStatus.loading &&
                (translation?.status != ItemDetailAiStatus.success ||
                    translation?.mode != mode) &&
                TextSanitizer.stripHtml(comment.text).isNotEmpty;
          })
          .map(translateComment),
    );

    emit(
      state.copyWith(
        threadTranslationLoadingIds: {
          for (final id in state.threadTranslationLoadingIds)
            if (id != node.comment.id) id,
        },
      ),
    );
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

  void _setCommentTranslation(int commentId, CommentTranslationState next) {
    emit(
      state.copyWith(
        commentTranslations: {...state.commentTranslations, commentId: next},
      ),
    );
  }

  List<HnItem> _flattenComments(CommentNode node) {
    return [
      node.comment,
      for (final child in node.children) ..._flattenComments(child),
    ];
  }

  String _errorMessage(Object error) {
    if (error is AiException) return error.message;
    return error.toString();
  }
}
