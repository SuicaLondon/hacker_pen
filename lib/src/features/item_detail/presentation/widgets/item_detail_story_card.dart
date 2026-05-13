import 'package:flutter/material.dart';

import '../../../../core/domain/hn_item.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/text_sanitizer.dart';
import '../../../../core/utils/time_formatter.dart';

class ItemDetailStoryCard extends StatelessWidget {
  const ItemDetailStoryCard({required this.story, super.key});

  final HnItem story;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bodyText = TextSanitizer.stripHtml(story.text);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            story.title,
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${story.by} ${TimeFormatter.relativeFromUnixSeconds(story.time)} | ${story.score} points',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              color: palette.textSecondary,
            ),
          ),
          if (story.url != null) ...[
            const SizedBox(height: 8),
            Text(
              story.url!,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                color: palette.brandOrange,
              ),
            ),
          ],
          if (bodyText.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              bodyText,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                color: palette.textPrimary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
