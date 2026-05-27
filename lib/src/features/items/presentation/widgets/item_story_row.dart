import 'package:flutter/material.dart';

import '../../../../core/domain/hn_item.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/utils/url_extensions.dart';

class ItemStoryRow extends StatelessWidget {
  const ItemStoryRow({
    required this.item,
    required this.rank,
    required this.onTap,
    super.key,
  });

  final HnItem item;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final metaStyle = textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    final rankStyle = textTheme.titleMedium?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w700,
    );
    final titleStyle = textTheme.titleMedium?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    final scoreStyle = textTheme.labelLarge?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w700,
    );
    final commentCountStyle = textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('$rank', textAlign: TextAlign.center, style: rankStyle),
            Expanded(
              child: Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.title,
                    style: titleStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item.url.hostOrFallback()} · by ${item.by} · ${TimeFormatter.relativeFromUnixSeconds(item.time)}',
                    style: metaStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              spacing: 4,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  spacing: 3,
                  mainAxisAlignment: .spaceBetween,
                  mainAxisSize: .min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: colorScheme.primary,
                      size: 14,
                    ),
                    Text('${item.score}', style: scoreStyle),
                  ],
                ),
                Row(
                  spacing: 4,
                  mainAxisAlignment: .spaceBetween,
                  mainAxisSize: .min,
                  children: [
                    Icon(
                      Icons.mode_comment_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 14,
                    ),
                    Text('${item.descendants}', style: commentCountStyle),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
