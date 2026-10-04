import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class HpActivityIndicator extends StatelessWidget {
  const HpActivityIndicator({this.size = 18, this.progress, super.key});

  final double size;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final value = progress;
    if (value != null) {
      return CupertinoActivityIndicator.partiallyRevealed(
        radius: size / 2,
        color: context.hpColors.brand,
        progress: value.clamp(0.0, 1.0),
      );
    }
    return CupertinoActivityIndicator(
      radius: size / 2,
      color: context.hpColors.brand,
      animating: !MediaQuery.disableAnimationsOf(context),
    );
  }
}

class HpLoadingView extends StatelessWidget {
  const HpLoadingView({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return Center(
      child: Semantics(
        label: label,
        liveRegion: true,
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 14,
          children: [
            const HpActivityIndicator(),
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.inkMuted,
                fontFamily: context.hpText.monoFamily,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
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
          dimension: 44,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: colors.paper,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.paper.withValues(alpha: 0.96),
          border: Border(bottom: BorderSide(color: colors.rule)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, topInset, 8, 0),
          child: SizedBox(
            height: 52,
            child: Row(
              spacing: 6,
              children: [
                ?leading,
                if (showMark) const _HpMark(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 2,
                    children: [
                      Text(
                        title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontFamily: context.hpText.monoFamily,
                          color: colors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (subtitle case final subtitle?) HpMetaText(subtitle),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HpSegmentTabs extends StatefulWidget {
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
  State<HpSegmentTabs> createState() => _HpSegmentTabsState();
}

class _HpSegmentTabsState extends State<HpSegmentTabs> {
  final _scroll = ScrollController();
  double _itemWidth = 0;

  @override
  void didUpdateWidget(covariant HpSegmentTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelection());
    }
  }

  void _revealSelection() {
    if (!mounted || !_scroll.hasClients) return;
    final left = widget.selectedIndex * _itemWidth;
    final right = left + _itemWidth;
    final viewport = _scroll.position.viewportDimension;
    final target =
        (left < _scroll.offset
                ? left
                : right > _scroll.offset + viewport
                ? right - viewport
                : _scroll.offset)
            .clamp(0.0, _scroll.position.maxScrollExtent);
    if (target == _scroll.offset) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return SizedBox(
      height: 52,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 5;
          if (_itemWidth != itemWidth) {
            _itemWidth = itemWidth;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _revealSelection(),
            );
          }

          return ListView.builder(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            itemCount: widget.tabs.length,
            itemExtent: itemWidth,
            itemBuilder: (context, index) {
              final isSelected = widget.selectedIndex == index;
              final label = widget.tabs[index].toUpperCase();

              return Semantics(
                button: true,
                selected: isSelected,
                label: label,
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => widget.onSelected(index),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isSelected ? colors.brand : colors.inkMuted,
                          fontFamily: context.hpText.monoFamily,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          height: 1,
                          letterSpacing: 1.4,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          width: 52,
                          height: 3,
                          color: isSelected ? colors.brand : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
    final rankLabel = rank.toString().padLeft(2, '0');

    return InkWell(
      onTap: onTap,
      child: ColoredBox(
        color: isSelected ? colors.highlight : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 48,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Semantics(
                      label: 'Rank $rank',
                      excludeSemantics: true,
                      child: Text(
                        rankLabel,
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: colors.brand,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              letterSpacing: -0.8,
                            ),
                      ),
                    ),
                  ),
                ),
                VerticalDivider(
                  width: context.hpBorders.standard,
                  thickness: context.hpBorders.standard,
                  color: colors.ruleStrong,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: Align(alignment: Alignment.topLeft, child: child),
                  ),
                ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: trailing!,
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
