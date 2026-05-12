import 'package:equatable/equatable.dart';

import '../../../core/domain/hn_item.dart';

class CommentNode extends Equatable {
  const CommentNode({required this.comment, required this.children});

  final HnItem comment;
  final List<CommentNode> children;

  @override
  List<Object?> get props => [comment, children];
}
