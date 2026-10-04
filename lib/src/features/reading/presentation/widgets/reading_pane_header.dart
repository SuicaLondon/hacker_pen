import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// Aligns contextual controls across the reading panes.
class ReadingPaneHeader extends StatelessWidget {
  const ReadingPaneHeader({required this.child, super.key});

  static const height = 56.0;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.rule)),
      ),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: child,
        ),
      ),
    );
  }
}
