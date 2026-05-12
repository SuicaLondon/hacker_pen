import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/domain/hn_item.dart';

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
    final metaStyle = const TextStyle(
      fontFamily: '.SF Pro Text',
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.2,
      letterSpacing: -0.1,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$rank',
                    style: const TextStyle(
                      fontFamily: '.SF Pro Display',
                      color: AppColors.brandOrange,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.keyboard_arrow_up,
                    color: AppColors.brandOrange,
                    size: 14,
                  ),
                  Text(
                    '${item.score}',
                    style: const TextStyle(
                      fontFamily: '.SF Pro Display',
                      color: AppColors.brandOrange,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: '.SF Pro Display',
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.24,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(_host(item.url), style: metaStyle),
                  const SizedBox(height: 4),
                  Text(
                    'by ${item.by} ${TimeFormatter.relativeFromUnixSeconds(item.time)}',
                    style: metaStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.mode_comment_outlined,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.descendants}',
                    style: const TextStyle(
                      fontFamily: '.SF Pro Text',
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _host(String? url) {
    if (url == null || url.isEmpty) return 'news.ycombinator.com';
    final uri = Uri.tryParse(url);
    return uri?.host.isNotEmpty == true ? uri!.host : 'news.ycombinator.com';
  }
}
