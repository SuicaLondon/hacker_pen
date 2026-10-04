import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class ItemsHeader extends StatelessWidget {
  const ItemsHeader({
    required this.selectedTab,
    required this.tabs,
    required this.onTabSelected,
    this.onSettingsPressed,
    this.isLogoVisible = true,
    super.key,
  });

  final int selectedTab;
  final List<String> tabs;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onSettingsPressed;
  final bool isLogoVisible;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final topInset = MediaQuery.paddingOf(context).top;

    return DecoratedBox(
      decoration: BoxDecoration(color: colors.paper),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: topInset),
            child: HpCollapsibleHeader(
              isVisible: isLogoVisible,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 12, 0),
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'HACKERPEN',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: colors.ink,
                                    fontFamily: context.hpText.displayFamily,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                    letterSpacing: 0.8,
                                  ),
                            ),
                          ),
                          if (onSettingsPressed != null)
                            _CompactHeaderIconButton(
                              tooltip: 'Settings',
                              onPressed: onSettingsPressed,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const HpDivider(),
                ],
              ),
            ),
          ),
          HpSegmentTabs(
            selectedIndex: selectedTab,
            tabs: tabs,
            onSelected: onTabSelected,
          ),
          const HpDivider(),
        ],
      ),
    );
  }
}

class _CompactHeaderIconButton extends StatelessWidget {
  const _CompactHeaderIconButton({required this.tooltip, this.onPressed});

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
          child: Center(
            child: CustomPaint(
              size: const Size(24, 20),
              painter: _SettingsGlyphPainter(
                lineColor: onPressed == null ? colors.inkSubtle : colors.ink,
                accentColor: onPressed == null
                    ? colors.inkSubtle
                    : colors.brand,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGlyphPainter extends CustomPainter {
  const _SettingsGlyphPainter({
    required this.lineColor,
    required this.accentColor,
  });

  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square;
    final accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.square;
    final rows = <(double, double)>[(3, 16), (10, 9), (17, 16)];

    for (final (y, markerX) in rows) {
      canvas.drawLine(Offset(1, y), Offset(size.width - 1, y), linePaint);
      canvas.drawLine(
        Offset(markerX, y - 3),
        Offset(markerX, y + 3),
        accentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SettingsGlyphPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.accentColor != accentColor;
  }
}
