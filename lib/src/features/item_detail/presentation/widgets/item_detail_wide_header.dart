import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/domain/hn_item.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/utils/url_extensions.dart';
import '../../../reading/presentation/widgets/reading_pane_header.dart';

class ItemDetailWideHeader extends StatelessWidget {
  const ItemDetailWideHeader({
    super.key,
    required this.story,
    this.onComments,
    this.onSummary,
    this.onClose,
    this.onShowNews,
  });

  final HnItem? story;
  final VoidCallback? onComments;
  final VoidCallback? onSummary;
  final VoidCallback? onClose;
  final VoidCallback? onShowNews;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final textTheme = Theme.of(context).textTheme;
    final item = story;
    final titleStyle = textTheme.titleSmall?.copyWith(color: colors.ink);
    final metadataStyle = textTheme.labelSmall?.copyWith(
      color: colors.inkMuted,
      fontFamily: context.hpText.monoFamily,
    );
    final textScaler = MediaQuery.textScalerOf(context);
    final showMetadata =
        textScaler.scale(titleStyle?.fontSize ?? 14) *
                (titleStyle?.height ?? 1.2) +
            textScaler.scale(metadataStyle?.fontSize ?? 11) *
                (metadataStyle?.height ?? 1.1) +
            4 <=
        ReadingPaneHeader.height - 8;
    final metadata = item == null
        ? 'Loading article'
        : '${item.url.hostOrFallback('Hacker News')} · '
              '${item.score} pts · ${item.by} · '
              '${TimeFormatter.compactRelativeFromUnixSeconds(item.time)}';

    return ReadingPaneHeader(
      key: const ValueKey('wide-reader-header'),
      child: Row(
        spacing: 10,
        children: [
          if (onShowNews != null)
            IconButton(
              tooltip: 'Show news list',
              onPressed: onShowNews,
              style: IconButton.styleFrom(
                foregroundColor: colors.inkMuted,
                fixedSize: const Size.square(32),
                minimumSize: const Size.square(32),
                padding: EdgeInsets.zero,
                iconSize: 18,
              ),
              icon: const Icon(Icons.vertical_split_outlined),
            ),
          Icon(
            item?.url?.isNotEmpty == true
                ? Icons.language_outlined
                : Icons.article_outlined,
            color: colors.inkMuted,
            size: 17,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Flexible(
                  child: Text(
                    item?.title ?? 'Article',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
                if (showMetadata)
                  Text(
                    metadata,
                    key: const ValueKey('article-metadata'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: metadataStyle,
                  ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('article-comments'),
            tooltip: item == null
                ? 'Comments'
                : 'Comments (${item.descendants})',
            onPressed: onComments,
            style: IconButton.styleFrom(
              foregroundColor: colors.inkMuted,
              fixedSize: const Size.square(32),
              minimumSize: const Size.square(32),
              padding: EdgeInsets.zero,
              iconSize: 18,
            ),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          if (item?.url?.isNotEmpty == true)
            IconButton(
              key: const ValueKey('article-summary'),
              tooltip: 'Summary',
              onPressed: onSummary,
              style: IconButton.styleFrom(
                foregroundColor: colors.inkMuted,
                fixedSize: const Size.square(32),
                minimumSize: const Size.square(32),
                padding: EdgeInsets.zero,
                iconSize: 18,
              ),
              icon: const Icon(Icons.summarize_outlined),
            ),
          if (onClose != null)
            IconButton(
              tooltip: 'Close article',
              onPressed: onClose,
              style: IconButton.styleFrom(
                foregroundColor: colors.inkMuted,
                fixedSize: const Size.square(32),
                minimumSize: const Size.square(32),
                padding: EdgeInsets.zero,
                iconSize: 17,
              ),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}
