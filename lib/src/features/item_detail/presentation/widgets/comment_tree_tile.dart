import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/domain/hn_item.dart';
import '../../../../core/ai/ai_translation_mode.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/text_sanitizer.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../domain/comment_node.dart';
import '../cubit/item_detail_state.dart';

class CommentTreeTile extends StatelessWidget {
  const CommentTreeTile({
    required this.node,
    this.depth = 0,
    this.translations = const <int, CommentTranslationState>{},
    this.translatingThreadRootIds = const <int>{},
    this.onTranslateComment,
    this.onTranslateReplies,
    super.key,
  });

  final CommentNode node;
  final int depth;
  final Map<int, CommentTranslationState> translations;
  final Set<int> translatingThreadRootIds;
  final ValueChanged<HnItem>? onTranslateComment;
  final ValueChanged<CommentNode>? onTranslateReplies;

  @override
  Widget build(BuildContext context) {
    final text = TextSanitizer.stripHtml(node.comment.text);

    if (text.isEmpty) {
      return _ReplyStack(
        children: node.children,
        depth: depth,
        translations: translations,
        translatingThreadRootIds: translatingThreadRootIds,
        onTranslateComment: onTranslateComment,
        onTranslateReplies: onTranslateReplies,
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        top: depth == 0 ? 4 : 0,
        left: depth == 0 ? 0 : 2,
      ),
      child: _CommentBlock(
        node: node,
        depth: depth,
        text: text,
        translations: translations,
        translatingThreadRootIds: translatingThreadRootIds,
        onTranslateComment: onTranslateComment,
        onTranslateReplies: onTranslateReplies,
      ),
    );
  }
}

class _CommentBlock extends StatelessWidget {
  const _CommentBlock({
    required this.node,
    required this.depth,
    required this.text,
    required this.translations,
    required this.translatingThreadRootIds,
    required this.onTranslateComment,
    required this.onTranslateReplies,
  });

  final CommentNode node;
  final int depth;
  final String text;
  final Map<int, CommentTranslationState> translations;
  final Set<int> translatingThreadRootIds;
  final ValueChanged<HnItem>? onTranslateComment;
  final ValueChanged<CommentNode>? onTranslateReplies;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final translation = translations[node.comment.id];
    final showsTranslation =
        translation?.status == ItemDetailAiStatus.success &&
        !translation!.showOriginal;
    final visibleText = showsTranslation ? translation.text ?? text : text;

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
            _CommentHeader(
              node: node,
              translation: translation,
              onTranslateComment: onTranslateComment,
            ),
            if (showsTranslation &&
                translation.mode == AiTranslationMode.paragraphPairs)
              _ParagraphPairTranslation(
                originalText: text,
                translatedText: translation.text ?? '',
              )
            else
              SelectableText(
                visibleText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.ink,
                  height: 1.36,
                ),
              ),
            if (translation?.status == ItemDetailAiStatus.failure &&
                translation?.errorMessage?.isNotEmpty == true)
              Text(
                translation!.errorMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.danger),
              ),
            if (node.children.isNotEmpty && onTranslateReplies != null)
              _TranslateRepliesButton(
                isLoading: translatingThreadRootIds.contains(node.comment.id),
                onPressed: () => onTranslateReplies?.call(node),
              ),
            if (node.children.isNotEmpty)
              _ReplyStack(
                children: node.children,
                depth: depth + 1,
                translations: translations,
                translatingThreadRootIds: translatingThreadRootIds,
                onTranslateComment: onTranslateComment,
                onTranslateReplies: onTranslateReplies,
              ),
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

class _ParagraphPairTranslation extends StatelessWidget {
  const _ParagraphPairTranslation({
    required this.originalText,
    required this.translatedText,
  });

  final String originalText;
  final String translatedText;

  @override
  Widget build(BuildContext context) {
    final originalParagraphs = _splitParagraphs(originalText);
    final translatedParagraphs = _splitParagraphs(translatedText);

    if (originalParagraphs.length == translatedParagraphs.length) {
      return Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < originalParagraphs.length; index++)
            _ParagraphPairBlock(
              original: originalParagraphs[index],
              translation: translatedParagraphs[index],
            ),
        ],
      );
    }

    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TranslationTextBlock(text: originalText),
        _TranslationTextBlock(text: translatedText),
      ],
    );
  }

  List<String> _splitParagraphs(String text) {
    return text
        .split(RegExp(r'\n\s*\n+'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList(growable: false);
  }
}

class _ParagraphPairBlock extends StatelessWidget {
  const _ParagraphPairBlock({
    required this.original,
    required this.translation,
  });

  final String original;
  final String translation;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TranslationTextBlock(text: original),
        _TranslationTextBlock(text: translation),
      ],
    );
  }
}

class _TranslationTextBlock extends StatelessWidget {
  const _TranslationTextBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return SelectableText(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: colors.ink, height: 1.36),
    );
  }
}

class _ReplyStack extends StatelessWidget {
  const _ReplyStack({
    required this.children,
    required this.depth,
    required this.translations,
    required this.translatingThreadRootIds,
    required this.onTranslateComment,
    required this.onTranslateReplies,
  });

  final List<CommentNode> children;
  final int depth;
  final Map<int, CommentTranslationState> translations;
  final Set<int> translatingThreadRootIds;
  final ValueChanged<HnItem>? onTranslateComment;
  final ValueChanged<CommentNode>? onTranslateReplies;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      children: List.generate(children.length, (index) {
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 4),
          child: CommentTreeTile(
            node: children[index],
            depth: depth,
            translations: translations,
            translatingThreadRootIds: translatingThreadRootIds,
            onTranslateComment: onTranslateComment,
            onTranslateReplies: onTranslateReplies,
          ),
        );
      }),
    );
  }
}

class _CommentHeader extends StatelessWidget {
  const _CommentHeader({
    required this.node,
    required this.translation,
    required this.onTranslateComment,
  });

  final CommentNode node;
  final CommentTranslationState? translation;
  final ValueChanged<HnItem>? onTranslateComment;

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
              _TranslateCommentButton(
                translation: translation,
                onPressed: onTranslateComment == null
                    ? null
                    : () => onTranslateComment?.call(node.comment),
              ),
            ],
          ),
        ),
        if (node.children.isNotEmpty) _ReplyCount(count: node.children.length),
      ],
    );
  }
}

class _TranslateCommentButton extends StatelessWidget {
  const _TranslateCommentButton({
    required this.translation,
    required this.onPressed,
  });

  final CommentTranslationState? translation;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final status = translation?.status ?? ItemDetailAiStatus.idle;
    final isLoading = status == ItemDetailAiStatus.loading;
    final isSuccess = status == ItemDetailAiStatus.success;
    final isFailure = status == ItemDetailAiStatus.failure;
    final showsOriginal = translation?.showOriginal ?? true;

    return Tooltip(
      message: isSuccess && !showsOriginal
          ? 'Show original'
          : 'Translate comment',
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: context.hpRadii.small,
        child: SizedBox.square(
          dimension: 28,
          child: Center(
            child: isLoading
                ? SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(
                      color: colors.inkMuted,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    isFailure
                        ? Icons.error_outline
                        : isSuccess && !showsOriginal
                        ? Icons.undo
                        : Icons.translate,
                    size: 15,
                    color: isFailure
                        ? colors.danger
                        : isSuccess
                        ? colors.brand
                        : colors.inkMuted,
                  ),
          ),
        ),
      ),
    );
  }
}

class _TranslateRepliesButton extends StatelessWidget {
  const _TranslateRepliesButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: SizedBox.square(
          dimension: 16,
          child: Center(
            child: isLoading
                ? CircularProgressIndicator(
                    color: colors.inkMuted,
                    strokeWidth: 2,
                  )
                : Icon(Icons.translate, size: 15, color: colors.brand),
          ),
        ),
        label: const Text('Translate replies'),
      ),
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
