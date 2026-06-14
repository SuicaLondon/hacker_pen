import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class ItemDetailCommentsFab extends StatelessWidget {
  const ItemDetailCommentsFab({
    required this.count,
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  final int count;
  final bool isLoading;
  final VoidCallback? onPressed;

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
        onTap: onPressed,
        borderRadius: context.hpRadii.medium,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              if (isLoading)
                SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    color: colors.inkMuted,
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(
                  Icons.mode_comment_outlined,
                  size: 16,
                  color: colors.brand,
                ),
              Text(
                isLoading ? 'Loading $count' : '$count comments',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: onPressed == null ? colors.inkSubtle : colors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
