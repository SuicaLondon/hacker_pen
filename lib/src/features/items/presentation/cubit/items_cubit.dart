import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/story_type.dart';
import '../../data/items_repository.dart';
import 'items_state.dart';

class ItemsCubit extends Cubit<ItemsState> {
  ItemsCubit(this._repository) : super(const ItemsState());

  final ItemsRepository _repository;
  int _requestGeneration = 0;
  int? _refreshGeneration;

  Future<void> loadItems({StoryType? storyType}) async {
    if (isClosed) return;

    final generation = ++_requestGeneration;
    _refreshGeneration = null;
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
      if (isClosed || generation != _requestGeneration) return;
      emit(state.copyWith(status: ItemsStatus.success, items: items));
    } catch (error) {
      if (isClosed || generation != _requestGeneration) return;
      emit(
        state.copyWith(
          status: ItemsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> refreshItems() async {
    if (isClosed ||
        state.status != ItemsStatus.success ||
        _refreshGeneration != null) {
      return;
    }

    final generation = ++_requestGeneration;
    _refreshGeneration = generation;
    final targetType = state.storyType;
    if (state.errorMessage != null) {
      emit(state.copyWith(errorMessage: null));
    }

    try {
      final items = await _repository.fetchItems(
        storyType: targetType,
        forceRefresh: true,
      );
      if (isClosed || generation != _requestGeneration) return;
      emit(state.copyWith(items: items));
    } catch (error) {
      if (isClosed || generation != _requestGeneration) return;
      emit(state.copyWith(errorMessage: error.toString()));
    } finally {
      if (_refreshGeneration == generation) {
        _refreshGeneration = null;
      }
    }
  }

  Future<void> syncWithUpdates() async {
    if (isClosed ||
        state.status != ItemsStatus.success ||
        _refreshGeneration != null) {
      return;
    }

    final generation = _requestGeneration;
    try {
      final refreshed = await _repository.refreshVisibleItemsIfChanged(
        storyType: state.storyType,
        currentItems: state.items,
      );
      if (isClosed || generation != _requestGeneration) return;
      if (refreshed != null) {
        emit(state.copyWith(items: refreshed));
      }
    } catch (_) {
      // Non-blocking background sync path; keep current UI state.
    }
  }
}
