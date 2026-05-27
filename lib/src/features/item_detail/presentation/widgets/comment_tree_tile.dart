import 'package:flutter/material.dart';

import '../../../../core/theme/app_fonts.dart';
import '../../../../core/utils/text_sanitizer.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../domain/comment_node.dart';

class CommentTreeTile extends StatelessWidget {
  const CommentTreeTile({required this.node, this.depth = 0, super.key});

  final CommentNode node;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final text = TextSanitizer.stripHtml(node.comment.text);

    if (text.isEmpty) {
      return _ReplyStack(children: node.children, depth: depth);
    }

    final card = Padding(
      padding: EdgeInsets.all(depth == 0 ? 4 : 0),
      child: _CommentCard(node: node, depth: depth, text: text),
    );

    return card;
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.node,
    required this.depth,
    required this.text,
  });

  final CommentNode node;
  final int depth;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRoot = depth == 0;
    const contentPadding = 9.0;
    const childGap = 6.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _surfaceColor(colorScheme, depth),
        borderRadius: BorderRadius.circular(isRoot ? 9 : 7),
        border: Border.all(
          color: isRoot
              ? colorScheme.outlineVariant.withValues(alpha: 0.72)
              : colorScheme.outlineVariant.withValues(alpha: 0.58),
          width: isRoot ? 1.15 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommentHeader(node: node),
            const SizedBox(height: 6),
            Text(
              text,
              style: TextStyle(
                fontFamily: AppFonts.text,
                color: colorScheme.onSurface,
                fontSize: 15,
                height: 1.43,
              ),
            ),
            if (node.children.isNotEmpty) ...[
              const SizedBox(height: childGap),
              _ReplyStack(children: node.children, depth: depth + 1),
            ],
          ],
        ),
      ),
    );
  }

  Color _surfaceColor(ColorScheme colorScheme, int depth) {
    if (depth == 0) return colorScheme.surfaceContainerLow;

    final opacity = depth.isEven ? 0.48 : 0.3;
    return colorScheme.surfaceContainerHigh.withValues(alpha: opacity);
  }
}

class _ReplyStack extends StatelessWidget {
  const _ReplyStack({required this.children, required this.depth});

  final List<CommentNode> children;
  final int depth;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      children: List.generate(children.length, (index) {
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 4),
          child: CommentTreeTile(node: children[index], depth: depth),
        );
      }),
    );
  }
}

class _CommentHeader extends StatelessWidget {
  const _CommentHeader({required this.node});

  final CommentNode node;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: node.comment.by,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text:
                      ' · ${TimeFormatter.relativeFromUnixSeconds(node.comment.time)}',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: AppFonts.text, fontSize: 13),
          ),
        ),
        if (node.children.isNotEmpty) ...[
          const SizedBox(width: 8),
          _ReplyCount(count: node.children.length),
        ],
      ],
    );
  }
}

class _ReplyCount extends StatelessWidget {
  const _ReplyCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mode_comment_outlined,
          size: 13,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: TextStyle(
            fontFamily: AppFonts.text,
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
