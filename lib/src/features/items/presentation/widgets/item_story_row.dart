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
    this.wideLayout = false,
    this.isSelected = false,
    super.key,
  });

  final HnItem item;
  final int rank;
  final VoidCallback onTap;
  final bool wideLayout;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    if (wideLayout) {
      return _NewsPaneStoryRow(
        item: item,
        rank: rank,
        onTap: onTap,
        isSelected: isSelected,
      );
    }
    final theme = Theme.of(context);
    final colors = context.hpColors;
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: colors.ink,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.25,
    );
    final metadata =
        '${item.score} PTS · ${item.descendants} COMMENTS · '
        '${TimeFormatter.compactRelativeFromUnixSeconds(item.time)}';

    return HpStoryRowShell(
      onTap: onTap,
      rank: rank,
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: titleStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Semantics(
            label:
                '${item.score} points, ${item.descendants} comments, '
                '${TimeFormatter.relativeFromUnixSeconds(item.time)}',
            excludeSemantics: true,
            child: Text(
              metadata,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.inkMuted,
                fontFamily: context.hpText.monoFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.15,
                letterSpacing: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsPaneStoryRow extends StatelessWidget {
  const _NewsPaneStoryRow({
    required this.item,
    required this.rank,
    required this.onTap,
    required this.isSelected,
  });

  final HnItem item;
  final int rank;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? colors.highlight : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? colors.brand : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 14, 14),
            child: Row(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Semantics(
                    label: 'Rank $rank',
                    excludeSemantics: true,
                    child: Text(
                      rank.toString().padLeft(2, '0'),
                      style: textTheme.labelSmall?.copyWith(
                        color: isSelected ? colors.brand : colors.inkSubtle,
                        fontFamily: context.hpText.monoFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.8,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: 6,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          letterSpacing: -0.15,
                        ),
                      ),
                      if (item.url case final url?)
                        Text(
                          url.hostOrFallback(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.inkMuted,
                            fontSize: 11,
                            height: 1.2,
                          ),
                        ),
                      Semantics(
                        label:
                            '${item.score} points, '
                            '${item.descendants} comments, '
                            '${TimeFormatter.relativeFromUnixSeconds(item.time)}',
                        excludeSemantics: true,
                        child: Text(
                          '${item.score} pts · '
                          '${item.descendants} comments · '
                          '${TimeFormatter.compactRelativeFromUnixSeconds(item.time)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.inkMuted,
                            fontFamily: context.hpText.monoFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
