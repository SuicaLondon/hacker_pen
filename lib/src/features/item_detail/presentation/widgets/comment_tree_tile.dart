import 'package:flutter/material.dart';

import '../../../../core/utils/text_sanitizer.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../domain/comment_node.dart';
import '../views/user_profile_page.dart';

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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isRoot = depth == 0;
    const contentPadding = 9.0;

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
          spacing: 6,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommentHeader(node: node),
            SelectableText(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            if (node.children.isNotEmpty) ...[
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: Row(
            spacing: 8,
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => UserProfilePage(userId: node.comment.by),
                    ),
                  );
                },
                child: Text(
                  node.comment.by,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  TimeFormatter.relativeFromUnixSeconds(node.comment.time),
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (node.children.isNotEmpty) ...[
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      spacing: 3,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mode_comment_outlined,
          size: 13,
          color: colorScheme.onSurfaceVariant,
        ),
        Text(
          '$count',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
