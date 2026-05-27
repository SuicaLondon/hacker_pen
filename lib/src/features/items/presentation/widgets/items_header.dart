import 'package:flutter/material.dart';

import '../../../../core/theme/app_fonts.dart';

class ItemsHeader extends StatelessWidget {
  const ItemsHeader({
    required this.selectedTab,
    required this.tabs,
    required this.onTabSelected,
    super.key,
  });

  final int selectedTab;
  final List<String> tabs;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colorScheme.surface, theme.scaffoldBackgroundColor],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 10, 12, 8),
            child: Row(
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Hacker',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'Pen',
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search, color: Colors.white),
                ),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: colorScheme.primary,
                  child: const Icon(
                    Icons.person,
                    size: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final isSelected = index == selectedTab;
                return InkWell(
                  onTap: () => onTabSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        tabs[index],
                        style: TextStyle(
                          fontFamily: AppFonts.text,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          fontSize: 17,
                          height: 1.1,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 26,
                        height: 2,
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
