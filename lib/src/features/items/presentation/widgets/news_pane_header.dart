import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../reading/presentation/widgets/reading_pane_header.dart';

class NewsPaneHeader extends StatelessWidget {
  const NewsPaneHeader({
    super.key,
    required this.onRefresh,
    this.onClose,
    this.onSettings,
  });

  final VoidCallback onRefresh;
  final VoidCallback? onClose;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final textTheme = Theme.of(context).textTheme;

    return ReadingPaneHeader(
      key: const ValueKey('wide-news-header'),
      child: Row(
        spacing: 4,
        children: [
          Expanded(
            child: Text(
              'News',
              style: textTheme.titleMedium?.copyWith(
                color: colors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh news list',
            onPressed: onRefresh,
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh),
          ),
          if (onSettings != null)
            IconButton(
              tooltip: 'Settings',
              onPressed: onSettings,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.settings_outlined),
            ),
          if (onClose != null)
            IconButton(
              tooltip: 'Hide news list',
              onPressed: onClose,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.vertical_split_outlined),
            ),
        ],
      ),
    );
  }
}
