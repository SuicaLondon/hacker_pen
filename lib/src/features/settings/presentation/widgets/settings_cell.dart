import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

class SettingsCell extends StatelessWidget {
  const SettingsCell({
    super.key,
    required this.title,
    required this.value,
    this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.hpColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                title,
                style: text.bodyLarge?.copyWith(color: colors.ink),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: text.bodyMedium?.copyWith(color: colors.inkMuted),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.inkSubtle),
          ],
        ),
      ),
    );
  }
}
