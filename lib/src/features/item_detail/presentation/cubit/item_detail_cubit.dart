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
  int _storyGeneration = 0;
  int _commentsGeneration = 0;
  int _aiGeneration = 0;

  /// Discards results from the previous AI configuration without reloading the
  /// article or starting another AI request.
  void invalidateAiResults() {
    if (isClosed) return;
    _aiGeneration++;
    emit(
      state.copyWith(
        summaryStatus: ItemDetailAiStatus.idle,
        summaryText: null,
        summaryErrorMessage: null,
        commentTranslations: const {},
        threadTranslationLoadingIds: const {},
      ),
    );
  }

  Future<void> load(int itemId) async {
    if (isClosed) return;
    final generation = ++_storyGeneration;
    final commentsGeneration = ++_commentsGeneration;
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
      if (!_isCurrent(generation)) return;
      emit(
        state.copyWith(
          storyStatus: ItemDetailStoryStatus.success,
          story: story,
          commentsStatus: ItemDetailCommentsStatus.loading,
          comments: const [],
          commentsErrorMessage: null,
        ),
      );

      await _loadCommentsForStory(story, generation, commentsGeneration);
    } catch (error) {
      if (!_isCurrent(generation)) return;
      emit(
        state.copyWith(
          storyStatus: ItemDetailStoryStatus.failure,
          storyErrorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> reloadComments() async {
    if (isClosed) return;
    final story = state.story;
    if (story == null) {
      return;
    }

    final generation = _storyGeneration;
    final commentsGeneration = ++_commentsGeneration;

    emit(
      state.copyWith(
        commentsStatus: ItemDetailCommentsStatus.loading,
        commentsErrorMessage: null,
        commentTranslations: const {},
        threadTranslationLoadingIds: const {},
      ),
    );
    await _loadCommentsForStory(story, generation, commentsGeneration);
  }

  Future<void> summarizeStory() async {
    if (isClosed) return;
    final generation = _storyGeneration;
    final aiGeneration = _aiGeneration;
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
      if (!_isCurrentAi(generation, aiGeneration)) return;
      emit(
        state.copyWith(
          summaryStatus: ItemDetailAiStatus.success,
          summaryText: summary,
          summaryErrorMessage: null,
        ),
      );
    } catch (error) {
      if (!_isCurrentAi(generation, aiGeneration)) return;
      emit(
        state.copyWith(
          summaryStatus: ItemDetailAiStatus.failure,
          summaryErrorMessage: _errorMessage(error),
        ),
      );
    }
  }

  Future<void> translateComment(HnItem comment) async {
    if (isClosed) return;
    final generation = _storyGeneration;
    final aiGeneration = _aiGeneration;
    final commentsGeneration = _commentsGeneration;
    try {
      final mode = await _aiContentRepository.loadTranslationMode();
      if (!_isCurrentAi(generation, aiGeneration, commentsGeneration)) return;
      final current = state.commentTranslations[comment.id];
      if (current?.status == ItemDetailAiStatus.loading) return;
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
      final translation = await _aiContentRepository.translateComment(
        comment.text ?? '',
      );
      if (!_isCurrentAi(generation, aiGeneration, commentsGeneration)) return;
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
      if (!_isCurrentAi(generation, aiGeneration, commentsGeneration)) return;
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
    if (isClosed ||
        node.children.isEmpty ||
        state.threadTranslationLoadingIds.contains(node.comment.id)) {
      return;
    }
    final generation = _storyGeneration;
    final aiGeneration = _aiGeneration;
    final commentsGeneration = _commentsGeneration;

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
    try {
      final mode = await _aiContentRepository.loadTranslationMode();
      if (!_isCurrentAi(generation, aiGeneration, commentsGeneration)) return;
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
    } catch (error) {
      if (!_isCurrentAi(generation, aiGeneration, commentsGeneration)) return;
      for (final comment in descendants) {
        _setCommentTranslation(
          comment.id,
          CommentTranslationState(
            status: ItemDetailAiStatus.failure,
            errorMessage: _errorMessage(error),
          ),
        );
      }
    } finally {
      if (_isCurrentAi(generation, aiGeneration, commentsGeneration)) {
        emit(
          state.copyWith(
            threadTranslationLoadingIds: {
              for (final id in state.threadTranslationLoadingIds)
                if (id != node.comment.id) id,
            },
          ),
        );
      }
    }
  }

  Future<void> _loadCommentsForStory(
    HnItem story,
    int generation,
    int commentsGeneration,
  ) async {
    try {
      final comments = await _repository.fetchCommentsForStory(story);
      if (!_isCurrent(generation, commentsGeneration)) return;
      emit(
        state.copyWith(
          commentsStatus: ItemDetailCommentsStatus.success,
          comments: comments,
        ),
      );
    } catch (error) {
      if (!_isCurrent(generation, commentsGeneration)) return;
      emit(
        state.copyWith(
          commentsStatus: ItemDetailCommentsStatus.failure,
          commentsErrorMessage: error.toString(),
        ),
      );
    }
  }

  bool _isCurrent(int generation, [int? commentsGeneration]) {
    return !isClosed &&
        generation == _storyGeneration &&
        (commentsGeneration == null ||
            commentsGeneration == _commentsGeneration);
  }

  bool _isCurrentAi(
    int generation,
    int aiGeneration, [
    int? commentsGeneration,
  ]) {
    return _isCurrent(generation, commentsGeneration) &&
        aiGeneration == _aiGeneration;
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
