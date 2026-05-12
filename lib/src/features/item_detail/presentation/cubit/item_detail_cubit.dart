import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/item_detail_repository.dart';
import 'item_detail_state.dart';

class ItemDetailCubit extends Cubit<ItemDetailState> {
  ItemDetailCubit(this._repository) : super(const ItemDetailState());

  final ItemDetailRepository _repository;

  Future<void> load(int itemId) async {
    emit(
      state.copyWith(
        status: ItemDetailStatus.loading,
        requestedItemId: itemId,
        errorMessage: null,
      ),
    );

    try {
      final detail = await _repository.fetchItemDetail(itemId);
      emit(state.copyWith(status: ItemDetailStatus.success, detail: detail));
    } catch (error) {
      emit(
        state.copyWith(
          status: ItemDetailStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
