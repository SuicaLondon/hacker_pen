import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/domain/hn_item.dart';
import '../../../../core/utils/time_formatter.dart';

class _StoryAppBarTitle extends StatelessWidget {
  const _StoryAppBarTitle({required this.story});

  final HnItem story;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.hpColors;
    final metadata =
        '${story.by.toUpperCase()} · ${story.score} PTS · '
        '${TimeFormatter.compactRelativeFromUnixSeconds(story.time)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 5,
      children: [
        Text(
          story.title,
          textAlign: TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        Text(
          metadata,
          textAlign: TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(
            color: colors.inkMuted,
            fontFamily: context.hpText.monoFamily,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class ItemDetailHeader extends StatelessWidget {
  const ItemDetailHeader({
    super.key,
    required this.story,
    required this.onSummaryPressed,
    required this.extendsPage,
    required this.showSafeAreaToggle,
    required this.onToggleSafeArea,
    required this.onBack,
    this.onComments,
  });

  final HnItem story;
  final VoidCallback? onSummaryPressed;
  final bool extendsPage;
  final bool showSafeAreaToggle;
  final VoidCallback? onToggleSafeArea;
  final VoidCallback onBack;
  final VoidCallback? onComments;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(bottom: BorderSide(color: colors.rule)),
      ),
      child: SizedBox(
        height: 76,
        child: Row(
          children: [
            HpIconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: Icons.arrow_back,
            ),
            Expanded(child: _StoryAppBarTitle(story: story)),
            if (onComments != null)
              HpIconButton(
                tooltip: 'Comments',
                onPressed: onComments,
                icon: Icons.chat_bubble_outline,
              ),
            if (showSafeAreaToggle)
              Semantics(
                toggled: extendsPage,
                child: IconButton(
                  isSelected: extendsPage,
                  style: IconButton.styleFrom(
                    foregroundColor: colors.inkMuted,
                    fixedSize: const Size.square(44),
                    minimumSize: const Size.square(44),
                    iconSize: 20,
                  ),
                  tooltip: extendsPage
                      ? 'Keep top safe area'
                      : 'Extend page to top',
                  onPressed: onToggleSafeArea,
                  icon: Icon(
                    extendsPage ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: extendsPage ? colors.brand : colors.inkMuted,
                  ),
                ),
              ),
            HpIconButton(
              tooltip: 'Summarize',
              onPressed: onSummaryPressed,
              icon: Icons.summarize_outlined,
            ),
          ],
        ),
      ),
    );
  }
}
