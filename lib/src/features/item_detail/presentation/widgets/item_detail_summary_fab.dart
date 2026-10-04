import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

class ItemDetailSummaryFab extends StatelessWidget {
  const ItemDetailSummaryFab({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.ruleStrong),
        borderRadius: context.hpRadii.medium,
      ),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: context.hpRadii.medium,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              if (isLoading)
                const HpActivityIndicator(size: 16)
              else
                Icon(Icons.summarize_outlined, size: 16, color: colors.brand),
              Text(
                isLoading ? 'SUMMARIZING' : 'SUMMARY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isLoading ? colors.inkSubtle : colors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
