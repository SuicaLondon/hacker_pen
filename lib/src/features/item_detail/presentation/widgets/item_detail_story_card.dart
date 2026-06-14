import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/domain/hn_item.dart';
import '../../../../core/utils/text_sanitizer.dart';
import '../../../../core/utils/time_formatter.dart';

class ItemDetailStoryCard extends StatelessWidget {
  const ItemDetailStoryCard({required this.story, super.key});

  final HnItem story;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final bodyText = TextSanitizer.stripHtml(story.text);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.58),
        border: Border.all(color: colors.rule),
        borderRadius: context.hpRadii.medium,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              story.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            HpMetaText(
              '${story.by} · ${TimeFormatter.relativeFromUnixSeconds(story.time)} · ${story.score} points',
            ),
            if (story.url != null) ...[
              const SizedBox(height: 8),
              Text(
                story.url!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: context.hpText.monoFamily,
                  color: colors.brand,
                ),
              ),
            ],
            if (bodyText.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                bodyText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.ink,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
