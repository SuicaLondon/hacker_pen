import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

class NewsCategoryTabs extends StatelessWidget {
  const NewsCategoryTabs({
    super.key,
    required this.selectedTab,
    required this.tabs,
    required this.onTabSelected,
  });

  final int selectedTab;
  final List<String> tabs;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final textTheme = Theme.of(context).textTheme;
    return ColoredBox(
      color: colors.paperAlt,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedTab == index;
          return Expanded(
            child: Semantics(
              selected: selected,
              child: InkWell(
                onTap: () => onTabSelected(index),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected ? colors.brand : colors.rule,
                        width: selected ? 2 : 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      tabs[index].toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: selected ? colors.ink : colors.inkMuted,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
