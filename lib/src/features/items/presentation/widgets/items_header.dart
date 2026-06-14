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
            padding: EdgeInsets.fromLTRB(12, topInset + 8, 8, 7),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.brand,
                    borderRadius: context.hpRadii.small,
                  ),
                  child: SizedBox.square(
                    dimension: 24,
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
                const SizedBox(width: 9),
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
                  HpIconButton(
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
