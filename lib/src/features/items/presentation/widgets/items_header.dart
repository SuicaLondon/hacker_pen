import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class ItemsHeader extends StatelessWidget {
  const ItemsHeader({
    required this.selectedTab,
    required this.tabs,
    required this.onTabSelected,
    this.onSettingsPressed,
    super.key,
  });

  final int selectedTab;
  final List<String> tabs;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hpColors;
    final topInset = MediaQuery.paddingOf(context).top;

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, topInset + 5, 8, 4),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.brand,
                    borderRadius: context.hpRadii.small,
                  ),
                  child: SizedBox.square(
                    dimension: 22,
                    child: Center(
                      child: Text(
                        'H',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.surface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'HackerPen',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.ink,
                      fontFamily: context.hpText.displayFamily,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (onSettingsPressed != null)
                  _CompactHeaderIconButton(
                    tooltip: 'Settings',
                    onPressed: onSettingsPressed,
                    icon: Icons.settings_outlined,
                  ),
              ],
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
  const _CompactHeaderIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
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
          dimension: 32,
          child: Icon(
            icon,
            color: onPressed == null ? colors.inkSubtle : colors.inkMuted,
            size: 18,
          ),
        ),
      ),
    );
  }
}
