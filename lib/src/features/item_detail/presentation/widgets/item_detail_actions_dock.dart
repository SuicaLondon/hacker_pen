import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../../core/design_system/design_system.dart';

/// Slides the actions into the trailing edge, leaving only a swipeable sliver.
class ItemDetailActionsDock extends StatefulWidget {
  const ItemDetailActionsDock({
    required this.scrollActivity,
    required this.child,
    super.key,
  });

  static const location = _ReadingActionsLocation();
  final Listenable scrollActivity;
  final Widget child;

  @override
  State<ItemDetailActionsDock> createState() => _ItemDetailActionsDockState();
}

class _ItemDetailActionsDockState extends State<ItemDetailActionsDock>
    with SingleTickerProviderStateMixin {
  static const _peekWidth = 14.0;
  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 380,
    ratio: 0.9,
  );
  late final AnimationController _expansion = AnimationController(
    vsync: this,
    value: 1,
  );
  final _actionsKey = GlobalKey();
  double _dragWidth = 1;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    widget.scrollActivity.addListener(_collapseOnScroll);
  }

  @override
  void didUpdateWidget(covariant ItemDetailActionsDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollActivity != widget.scrollActivity) {
      oldWidget.scrollActivity.removeListener(_collapseOnScroll);
      widget.scrollActivity.addListener(_collapseOnScroll);
    }
  }

  void _collapseOnScroll() {
    if (_expansion.value == 0 || (_isClosing && _expansion.isAnimating)) return;
    _settle(false);
  }

  void _settle(bool expanded, {double velocity = 0}) {
    _isClosing = !expanded;
    final target = expanded ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _expansion.value = target;
    } else {
      _expansion.animateWith(
        SpringSimulation(
          _spring,
          _expansion.value,
          target,
          velocity.clamp(-8.0, 8.0),
          snapToEnd: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    widget.scrollActivity.removeListener(_collapseOnScroll);
    _expansion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onHorizontalDragStart: (_) {
        _isClosing = false;
        _expansion.stop();
        _dragWidth = (_actionsKey.currentContext?.size?.width ?? 1).clamp(
          1.0,
          double.infinity,
        );
      },
      onHorizontalDragUpdate: (details) {
        _expansion.value -= details.primaryDelta! / _dragWidth;
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        _settle(
          velocity.abs() > 250 ? velocity < 0 : _expansion.value >= 0.5,
          velocity: -velocity / _dragWidth,
        );
      },
      onHorizontalDragCancel: () => _settle(_expansion.value >= 0.5),
      child: AnimatedBuilder(
        animation: _expansion,
        child: Padding(
          key: _actionsKey,
          padding: const EdgeInsets.only(right: kFloatingActionButtonMargin),
          child: widget.child,
        ),
        builder: (context, actions) {
          final progress = _expansion.value;
          final expanded = progress >= 0.5;
          return Semantics(
            container: true,
            label: 'Reading actions',
            expanded: expanded,
            hint: expanded ? 'Swipe right to hide' : 'Swipe left to show',
            onIncrease: expanded ? null : () => _settle(true),
            onDecrease: expanded ? () => _settle(false) : null,
            child: ClipRect(
              child: CustomPaint(
                painter: _EdgeActionsPainter(
                  progress: progress,
                  surface: colors.surface,
                  border: colors.ruleStrong,
                  accent: colors.brand,
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: _peekWidth * (1 - progress)),
                  child: ClipRect(
                    child: Align(
                      widthFactor: progress,
                      heightFactor: lerpDouble(0.55, 1, progress),
                      alignment: Alignment.bottomLeft,
                      child: IgnorePointer(
                        ignoring: progress < 1,
                        child: ExcludeSemantics(
                          excluding: progress < 1,
                          child: Opacity(
                            opacity: const Interval(
                              0.65,
                              1,
                            ).transform(progress),
                            child: actions,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Retains the original bottom spacing; only the collapsed sliver meets the edge.
class _ReadingActionsLocation extends FloatingActionButtonLocation {
  const _ReadingActionsLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final original = FloatingActionButtonLocation.endFloat.getOffset(geometry);
    return Offset(
      geometry.scaffoldSize.width -
          geometry.minInsets.right -
          geometry.floatingActionButtonSize.width,
      original.dy,
    );
  }
}

/// A single edge sliver separates into the two action surfaces during expansion.
class _EdgeActionsPainter extends CustomPainter {
  const _EdgeActionsPainter({
    required this.progress,
    required this.surface,
    required this.border,
    required this.accent,
  });

  final double progress;
  final Color surface;
  final Color border;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final fade = 1 - const Interval(0.65, 0.98).transform(progress);
    if (fade == 0) return;
    final split = Curves.easeInOut.transform(progress);
    final right = size.width - kFloatingActionButtonMargin * progress;
    final gap = 10 * split;
    final full = Rect.fromLTRB(0.5, 0.5, right, size.height - 0.5);
    for (final lower in [false, true]) {
      final target = Rect.fromLTRB(
        0.5,
        lower ? (size.height + gap) / 2 : 0.5,
        right,
        lower ? size.height - 0.5 : (size.height - gap) / 2,
      );
      final shape = RRect.fromRectAndCorners(
        Rect.lerp(full, target, split)!,
        topLeft: Radius.circular(lerpDouble(22, 8, progress)!),
        bottomLeft: Radius.circular(lerpDouble(22, 8, progress)!),
        topRight: Radius.circular(8 * progress),
        bottomRight: Radius.circular(8 * progress),
      );
      canvas.drawRRect(shape, Paint()..color = surface.withValues(alpha: fade));
      canvas.drawRRect(
        shape,
        Paint()
          ..color = border.withValues(alpha: fade)
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.drawLine(
      Offset(6, size.height / 2 - 7),
      Offset(6, size.height / 2 + 7),
      Paint()
        ..color = accent.withValues(alpha: (1 - progress) * fade)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_EdgeActionsPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      surface != oldDelegate.surface ||
      border != oldDelegate.border ||
      accent != oldDelegate.accent;
}
