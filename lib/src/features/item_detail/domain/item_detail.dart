import 'package:equatable/equatable.dart';

import '../../../core/domain/hn_item.dart';
import 'comment_node.dart';

class ItemDetail extends Equatable {
  const ItemDetail({required this.story, required this.comments});

  final HnItem story;
  final List<CommentNode> comments;

  @override
  List<Object?> get props => [story, comments];
}
