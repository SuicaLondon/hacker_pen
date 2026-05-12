import 'package:equatable/equatable.dart';

import '../../domain/item_detail.dart';

enum ItemDetailStatus { initial, loading, success, failure }

class ItemDetailState extends Equatable {
  const ItemDetailState({
    this.status = ItemDetailStatus.initial,
    this.requestedItemId,
    this.detail,
    this.errorMessage,
  });

  final ItemDetailStatus status;
  final int? requestedItemId;
  final ItemDetail? detail;
  final String? errorMessage;

  ItemDetailState copyWith({
    ItemDetailStatus? status,
    int? requestedItemId,
    ItemDetail? detail,
    String? errorMessage,
  }) {
    return ItemDetailState(
      status: status ?? this.status,
      requestedItemId: requestedItemId ?? this.requestedItemId,
      detail: detail ?? this.detail,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, requestedItemId, detail, errorMessage];
}
