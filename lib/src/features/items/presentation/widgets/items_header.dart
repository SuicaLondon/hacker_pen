import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF101010), AppColors.background],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
            child: Row(
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: '.SF Pro Display',
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                    children: [
                      TextSpan(
                        text: 'Hacker',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'Pen',
                        style: TextStyle(color: AppColors.brandOrange),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search, color: Colors.white),
                ),
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.brandOrange,
                  child: Icon(Icons.person, size: 14, color: Colors.black),
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
                          fontFamily: '.SF Pro Text',
                          color: isSelected
                              ? AppColors.brandOrange
                              : AppColors.textMuted,
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
                            ? AppColors.brandOrange
                            : Colors.transparent,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }
}
