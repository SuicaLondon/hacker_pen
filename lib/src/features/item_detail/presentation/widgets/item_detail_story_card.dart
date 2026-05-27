import 'package:flutter/material.dart';

import '../../../../core/domain/hn_item.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/utils/text_sanitizer.dart';
import '../../../../core/utils/time_formatter.dart';

class ItemDetailStoryCard extends StatelessWidget {
  const ItemDetailStoryCard({required this.story, super.key});

  final HnItem story;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bodyText = TextSanitizer.stripHtml(story.text);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            story.title,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${story.by} ${TimeFormatter.relativeFromUnixSeconds(story.time)} | ${story.score} points',
            style: TextStyle(
              fontFamily: AppFonts.text,
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (story.url != null) ...[
            const SizedBox(height: 8),
            Text(
              story.url!,
              style: TextStyle(
                fontFamily: AppFonts.text,
                fontSize: 14,
                color: colorScheme.primary,
              ),
            ),
          ],
          if (bodyText.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              bodyText,
              style: TextStyle(
                fontFamily: AppFonts.text,
                fontSize: 16,
                color: colorScheme.onSurface,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
