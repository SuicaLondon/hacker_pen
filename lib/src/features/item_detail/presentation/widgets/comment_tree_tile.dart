import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/text_sanitizer.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../domain/comment_node.dart';

class CommentTreeTile extends StatelessWidget {
  const CommentTreeTile({required this.node, this.depth = 0, super.key});

  final CommentNode node;
  final int depth;

  @override
  Widget build(BuildContext context) {
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
              ? const Color(0xFF111111)
              : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${node.comment.by} · ${TimeFormatter.relativeFromUnixSeconds(node.comment.time)}',
              style: const TextStyle(
                fontFamily: '.SF Pro Text',
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                fontFamily: '.SF Pro Text',
                color: AppColors.textPrimary,
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
