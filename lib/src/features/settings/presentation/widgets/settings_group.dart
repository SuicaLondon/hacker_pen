import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title!.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.hpColors.inkMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
        Material(
          color: context.hpColors.surface,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: HpDivider(),
                  ),
                children[index],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
