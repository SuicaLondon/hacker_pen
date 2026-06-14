import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
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
    final colors = context.hpColors;
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: colors.ink,
      fontWeight: FontWeight.w600,
      height: 1.18,
    );
    final scoreStyle = theme.textTheme.labelLarge?.copyWith(
      color: colors.brand,
      fontWeight: FontWeight.w800,
    );
    final commentCountStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colors.inkMuted,
      fontFamily: context.hpText.monoFamily,
    );

    return HpStoryRowShell(
      onTap: onTap,
      rank: rank,
      trailing: SizedBox(
        width: 58,
        child: Column(
          spacing: 5,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${item.score}', style: scoreStyle),
            Row(
              spacing: 4,
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mode_comment_outlined,
                  color: colors.inkMuted,
                  size: 13,
                ),
                Flexible(
                  child: Text(
                    '${item.descendants}',
                    overflow: TextOverflow.ellipsis,
                    style: commentCountStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      child: Column(
        spacing: 4,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: titleStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          HpMetaText(
            '${item.url.hostOrFallback()} · ${item.by} · ${TimeFormatter.relativeFromUnixSeconds(item.time)}',
          ),
        ],
      ),
    );
  }
}
