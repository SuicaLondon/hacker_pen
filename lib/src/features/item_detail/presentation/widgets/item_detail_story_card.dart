import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/text_sanitizer.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/domain/hn_item.dart';

class ItemDetailStoryCard extends StatelessWidget {
  const ItemDetailStoryCard({required this.story, super.key});

  final HnItem story;

  @override
  Widget build(BuildContext context) {
    final bodyText = TextSanitizer.stripHtml(story.text);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            story.title,
            style: const TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${story.by} ${TimeFormatter.relativeFromUnixSeconds(story.time)} | ${story.score} points',
            style: const TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (story.url != null) ...[
            const SizedBox(height: 8),
            Text(
              story.url!,
              style: const TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                color: AppColors.brandOrange,
              ),
            ),
          ],
          if (bodyText.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              bodyText,
              style: const TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
