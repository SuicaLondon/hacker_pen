import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'hp_components.dart';
import 'hp_tokens.dart';

class HpSliverRefreshControl extends StatelessWidget {
  const HpSliverRefreshControl({required this.onRefresh, super.key});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      refreshIndicatorExtent: 56,
      onRefresh: onRefresh,
      builder: _buildRefreshIndicator,
    );
  }

  Widget _buildRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode mode,
    double pulledExtent,
    double triggerDistance,
    double indicatorExtent,
  ) {
    if (mode == RefreshIndicatorMode.inactive) return const SizedBox.shrink();

    final progress = (pulledExtent / triggerDistance).clamp(0.0, 1.0);
    final refreshing =
        mode == RefreshIndicatorMode.armed ||
        mode == RefreshIndicatorMode.refresh;
    final retracting = mode == RefreshIndicatorMode.done;
    final label = refreshing || retracting ? 'Refreshing' : 'Pull to refresh';

    return ClipRect(
      child: OverflowBox(
        minHeight: indicatorExtent,
        maxHeight: indicatorExtent,
        alignment: Alignment.bottomCenter,
        child: Opacity(
          opacity: (pulledExtent / indicatorExtent).clamp(0.0, 1.0),
          child: Semantics(
            label: label,
            liveRegion: refreshing,
            excludeSemantics: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 10,
              children: [
                HpActivityIndicator(
                  progress: refreshing ? null : (retracting ? 1 : progress),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.hpColors.inkMuted,
                    fontFamily: context.hpText.monoFamily,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
