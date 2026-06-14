import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/app_routes.dart';
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

    return Padding(
      padding: EdgeInsets.only(
        top: depth == 0 ? 4 : 0,
        left: depth == 0 ? 0 : 2,
      ),
      child: _CommentBlock(node: node, depth: depth, text: text),
    );
  }
}

class _CommentBlock extends StatelessWidget {
  const _CommentBlock({
    required this.node,
    required this.depth,
    required this.text,
  });

  final CommentNode node;
  final int depth;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _surfaceColor(colors, depth),
        border: Border(
          left: BorderSide(
            color: depth == 0
                ? colors.ruleStrong
                : colors.brand.withValues(alpha: 0.38),
            width: depth == 0 ? 1 : 2,
          ),
          top: BorderSide(color: colors.rule.withValues(alpha: 0.72)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 8, 7, 8),
        child: Column(
          spacing: 6,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommentHeader(node: node),
            SelectableText(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.ink, height: 1.36),
            ),
            if (node.children.isNotEmpty)
              _ReplyStack(children: node.children, depth: depth + 1),
          ],
        ),
      ),
    );
  }

  Color _surfaceColor(HpColors colors, int depth) {
    if (depth == 0) return colors.surface.withValues(alpha: 0.5);
    return depth.isEven
        ? colors.surfaceMuted.withValues(alpha: 0.48)
        : colors.highlight.withValues(alpha: 0.42);
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
    final colors = context.hpColors;

    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: Row(
            spacing: 8,
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.userProfile,
                    arguments: node.comment.by,
                  );
                },
                child: Text(
                  node.comment.by,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: HpMetaText(
                  TimeFormatter.relativeFromUnixSeconds(node.comment.time),
                ),
              ),
            ],
          ),
        ),
        if (node.children.isNotEmpty) _ReplyCount(count: node.children.length),
      ],
    );
  }
}

class _ReplyCount extends StatelessWidget {
  const _ReplyCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return Row(
      spacing: 3,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mode_comment_outlined, size: 13, color: colors.inkMuted),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.inkMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
