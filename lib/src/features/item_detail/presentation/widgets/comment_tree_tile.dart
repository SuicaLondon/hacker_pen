import 'package:flutter/material.dart';

import '../../../../core/utils/text_sanitizer.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../domain/comment_node.dart';

class CommentTreeTile extends StatelessWidget {
  const CommentTreeTile({required this.node, this.depth = 0, super.key});

  final CommentNode node;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final marginLeft = (depth * 14).clamp(0, 42).toDouble();
    final text = TextSanitizer.stripHtml(node.comment.text);

    if (text.isEmpty) {
      return Column(
        children: node.children
            .map((child) => CommentTreeTile(node: child, depth: depth + 1))
            .toList(growable: false),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16 + marginLeft, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: depth.isEven
              ? colorScheme.surfaceContainerLow
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${node.comment.by} · ${TimeFormatter.relativeFromUnixSeconds(node.comment.time)}',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                color: colorScheme.onSurface,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (node.children.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...node.children.map(
                (child) => CommentTreeTile(node: child, depth: depth + 1),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
