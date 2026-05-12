import 'package:equatable/equatable.dart';

import '../../../../core/domain/hn_item.dart';
import '../../../../core/domain/story_type.dart';

enum ItemsStatus { initial, loading, success, failure }

class ItemsState extends Equatable {
  const ItemsState({
    this.status = ItemsStatus.initial,
    this.items = const <HnItem>[],
    this.storyType = StoryType.top,
    this.errorMessage,
  });

  final ItemsStatus status;
  final List<HnItem> items;
  final StoryType storyType;
  final String? errorMessage;

  ItemsState copyWith({
    ItemsStatus? status,
    List<HnItem>? items,
    StoryType? storyType,
    String? errorMessage,
  }) {
    return ItemsState(
      status: status ?? this.status,
      items: items ?? this.items,
      storyType: storyType ?? this.storyType,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, storyType, errorMessage];
}
