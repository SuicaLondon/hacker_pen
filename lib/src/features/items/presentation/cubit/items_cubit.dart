import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/story_type.dart';
import '../../data/items_repository.dart';
import 'items_state.dart';

class ItemsCubit extends Cubit<ItemsState> {
  ItemsCubit(this._repository) : super(const ItemsState());

  final ItemsRepository _repository;

  Future<void> loadItems({StoryType? storyType}) async {
    final targetType = storyType ?? state.storyType;
    emit(
      state.copyWith(
        status: ItemsStatus.loading,
        storyType: targetType,
        errorMessage: null,
      ),
    );

    try {
      final items = await _repository.fetchItems(storyType: targetType);
      emit(state.copyWith(status: ItemsStatus.success, items: items));
    } catch (error) {
      emit(
        state.copyWith(
          status: ItemsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
