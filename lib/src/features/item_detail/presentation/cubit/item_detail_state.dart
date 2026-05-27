import 'package:equatable/equatable.dart';

import '../../../../core/domain/hn_item.dart';
import '../../domain/comment_node.dart';

enum ItemDetailStoryStatus { initial, loading, success, failure }

enum ItemDetailCommentsStatus { initial, loading, success, failure }

class ItemDetailState extends Equatable {
  const ItemDetailState({
    this.requestedItemId,
    this.storyStatus = ItemDetailStoryStatus.initial,
    this.commentsStatus = ItemDetailCommentsStatus.initial,
    this.story,
    this.comments = const <CommentNode>[],
    this.storyErrorMessage,
    this.commentsErrorMessage,
  });

  final int? requestedItemId;
  final ItemDetailStoryStatus storyStatus;
  final ItemDetailCommentsStatus commentsStatus;
  final HnItem? story;
  final List<CommentNode> comments;
  final String? storyErrorMessage;
  final String? commentsErrorMessage;

  ItemDetailState copyWith({
    int? requestedItemId,
    ItemDetailStoryStatus? storyStatus,
    ItemDetailCommentsStatus? commentsStatus,
    HnItem? story,
    List<CommentNode>? comments,
    String? storyErrorMessage,
    String? commentsErrorMessage,
  }) {
    return ItemDetailState(
      requestedItemId: requestedItemId ?? this.requestedItemId,
      storyStatus: storyStatus ?? this.storyStatus,
      commentsStatus: commentsStatus ?? this.commentsStatus,
      story: story ?? this.story,
      comments: comments ?? this.comments,
      storyErrorMessage: storyErrorMessage,
      commentsErrorMessage: commentsErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    requestedItemId,
    storyStatus,
    commentsStatus,
    story,
    comments,
    storyErrorMessage,
    commentsErrorMessage,
  ];
}
