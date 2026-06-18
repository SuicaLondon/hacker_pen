import 'package:equatable/equatable.dart';

import '../../../../core/domain/hn_item.dart';
import '../../../../core/ai/ai_translation_mode.dart';
import '../../domain/comment_node.dart';

enum ItemDetailStoryStatus { initial, loading, success, failure }

enum ItemDetailCommentsStatus { initial, loading, success, failure }

enum ItemDetailAiStatus { idle, loading, success, failure }

const _unset = Object();

class CommentTranslationState extends Equatable {
  const CommentTranslationState({
    this.status = ItemDetailAiStatus.idle,
    this.text,
    this.errorMessage,
    this.showOriginal = false,
    this.mode,
  });

  final ItemDetailAiStatus status;
  final String? text;
  final String? errorMessage;
  final bool showOriginal;
  final AiTranslationMode? mode;

  CommentTranslationState copyWith({
    ItemDetailAiStatus? status,
    Object? text = _unset,
    Object? errorMessage = _unset,
    bool? showOriginal,
    Object? mode = _unset,
  }) {
    return CommentTranslationState(
      status: status ?? this.status,
      text: text == _unset ? this.text : text as String?,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      showOriginal: showOriginal ?? this.showOriginal,
      mode: mode == _unset ? this.mode : mode as AiTranslationMode?,
    );
  }

  @override
  List<Object?> get props => [status, text, errorMessage, showOriginal, mode];
}

class ItemDetailState extends Equatable {
  const ItemDetailState({
    this.requestedItemId,
    this.storyStatus = ItemDetailStoryStatus.initial,
    this.commentsStatus = ItemDetailCommentsStatus.initial,
    this.summaryStatus = ItemDetailAiStatus.idle,
    this.story,
    this.comments = const <CommentNode>[],
    this.storyErrorMessage,
    this.commentsErrorMessage,
    this.summaryText,
    this.summaryErrorMessage,
    this.commentTranslations = const <int, CommentTranslationState>{},
    this.threadTranslationLoadingIds = const <int>{},
  });

  final int? requestedItemId;
  final ItemDetailStoryStatus storyStatus;
  final ItemDetailCommentsStatus commentsStatus;
  final ItemDetailAiStatus summaryStatus;
  final HnItem? story;
  final List<CommentNode> comments;
  final String? storyErrorMessage;
  final String? commentsErrorMessage;
  final String? summaryText;
  final String? summaryErrorMessage;
  final Map<int, CommentTranslationState> commentTranslations;
  final Set<int> threadTranslationLoadingIds;

  ItemDetailState copyWith({
    Object? requestedItemId = _unset,
    ItemDetailStoryStatus? storyStatus,
    ItemDetailCommentsStatus? commentsStatus,
    ItemDetailAiStatus? summaryStatus,
    Object? story = _unset,
    List<CommentNode>? comments,
    Object? storyErrorMessage = _unset,
    Object? commentsErrorMessage = _unset,
    Object? summaryText = _unset,
    Object? summaryErrorMessage = _unset,
    Map<int, CommentTranslationState>? commentTranslations,
    Set<int>? threadTranslationLoadingIds,
  }) {
    return ItemDetailState(
      requestedItemId: requestedItemId == _unset
          ? this.requestedItemId
          : requestedItemId as int?,
      storyStatus: storyStatus ?? this.storyStatus,
      commentsStatus: commentsStatus ?? this.commentsStatus,
      summaryStatus: summaryStatus ?? this.summaryStatus,
      story: story == _unset ? this.story : story as HnItem?,
      comments: comments ?? this.comments,
      storyErrorMessage: storyErrorMessage == _unset
          ? this.storyErrorMessage
          : storyErrorMessage as String?,
      commentsErrorMessage: commentsErrorMessage == _unset
          ? this.commentsErrorMessage
          : commentsErrorMessage as String?,
      summaryText: summaryText == _unset
          ? this.summaryText
          : summaryText as String?,
      summaryErrorMessage: summaryErrorMessage == _unset
          ? this.summaryErrorMessage
          : summaryErrorMessage as String?,
      commentTranslations: commentTranslations ?? this.commentTranslations,
      threadTranslationLoadingIds:
          threadTranslationLoadingIds ?? this.threadTranslationLoadingIds,
    );
  }

  @override
  List<Object?> get props => [
    requestedItemId,
    storyStatus,
    commentsStatus,
    summaryStatus,
    story,
    comments,
    storyErrorMessage,
    commentsErrorMessage,
    summaryText,
    summaryErrorMessage,
    commentTranslations,
    threadTranslationLoadingIds,
  ];
}
