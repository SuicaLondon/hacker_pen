import 'package:flutter/material.dart';

import 'hp_tokens.dart';

class HpDivider extends StatelessWidget {
  const HpDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: context.hpBorders.hairline,
      thickness: context.hpBorders.hairline,
      color: context.hpColors.rule,
    );
  }
}

class HpMetaText extends StatelessWidget {
  const HpMetaText(this.data, {this.maxLines = 1, this.textAlign, super.key});

  final String data;
  final int maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: context.hpColors.inkMuted,
        fontFamily: context.hpText.monoFamily,
      ),
    );
  }
}

class HpIconButton extends StatelessWidget {
  const HpIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: context.hpRadii.small,
        child: SizedBox.square(
          dimension: 38,
          child: Icon(
            icon,
            color: onPressed == null ? colors.inkSubtle : colors.inkMuted,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class HpTopBar extends StatelessWidget {
  const HpTopBar({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.showMark = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final topInset = MediaQuery.paddingOf(context).top;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper.withValues(alpha: 0.96),
        border: Border(bottom: BorderSide(color: colors.rule)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, topInset + 8, 8, 8),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            if (showMark) ...[const _HpMark(), const SizedBox(width: 9)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: context.hpText.displayFamily,
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle case final subtitle?) ...[
                    const SizedBox(height: 2),
                    HpMetaText(subtitle),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class HpSegmentTabs extends StatelessWidget {
  const HpSegmentTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;

          return InkWell(
            onTap: () => onSelected(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  tabs[index],
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? colors.brand : colors.inkMuted,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 22,
                  height: 2,
                  color: isSelected ? colors.brand : Colors.transparent,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HpStoryRowShell extends StatelessWidget {
  const HpStoryRowShell({
    required this.rank,
    required this.child,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    super.key,
  });

  final int rank;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return InkWell(
      onTap: onTap,
      child: ColoredBox(
        color: isSelected ? colors.highlight : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '$rank',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: child),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class HpSheetScaffold extends StatelessWidget {
  const HpSheetScaffold({
    required this.title,
    required this.body,
    this.leading,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      child: ColoredBox(
        color: colors.paper,
        child: Column(
          children: [
            HpTopBar(title: title, leading: leading, trailing: trailing),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class HpSettingsSection extends StatelessWidget {
  const HpSettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.58),
        border: Border.all(color: colors.rule),
        borderRadius: context.hpRadii.medium,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.brand,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _HpMark extends StatelessWidget {
  const _HpMark();

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.brand,
        borderRadius: context.hpRadii.small,
      ),
      child: SizedBox.square(
        dimension: 22,
        child: Center(
          child: Text(
            'H',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.surface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
