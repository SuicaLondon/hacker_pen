import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Uses accumulated travel so slow scrolling works without reacting to jitter.
class HpScrollHeaderController extends ChangeNotifier {
  bool _isVisible = true;
  double _lastOffset = 0;
  double _travel = 0;
  double? _userDirection;

  bool get isVisible => _isVisible;

  /// Positive travel moves down the document. Keep this intent through inertia
  /// so bounce and layout corrections cannot reverse the header on their own.
  void recordUserScroll(double delta) {
    if (!delta.isFinite || delta == 0) return;
    if (_userDirection != delta.sign) _travel = 0;
    _userDirection = delta.sign;
  }

  bool handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is UserScrollNotification) {
      switch (notification.direction) {
        case ScrollDirection.forward:
          recordUserScroll(-1);
        case ScrollDirection.reverse:
          recordUserScroll(1);
        case ScrollDirection.idle:
          break;
      }
    } else if (notification is ScrollUpdateNotification) {
      final dragDelta = notification.dragDetails?.primaryDelta;
      if (dragDelta != null) recordUserScroll(-dragDelta);
      update(
        notification.metrics.pixels.clamp(
          0.0,
          notification.metrics.maxScrollExtent.clamp(0.0, double.infinity),
        ),
      );
    }
    return false;
  }

  void update(double offset) {
    if (!offset.isFinite) return;
    final current = offset < 0 ? 0.0 : offset;
    final delta = current - _lastOffset;
    _lastOffset = current;

    if (_userDirection != null && delta.sign != _userDirection) return;

    if (current <= 8) {
      _travel = 0;
      _setVisible(true);
      return;
    }
    if (delta == 0) return;
    if (_travel.sign != delta.sign) _travel = 0;
    _travel += delta;

    if (_travel >= 24 && current >= 80) {
      _setVisible(false);
    } else if (_travel <= -16) {
      _setVisible(true);
    }
  }

  void reset({double offset = 0}) {
    _lastOffset = offset;
    _travel = 0;
    _userDirection = null;
    _setVisible(true);
  }

  void _setVisible(bool value) {
    if (_isVisible == value) return;
    _isVisible = value;
    _travel = 0;
    notifyListeners();
  }
}

class HpCollapsibleHeader extends StatelessWidget {
  const HpCollapsibleHeader({
    required this.isVisible,
    required this.child,
    super.key,
  });

  final bool isVisible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.topCenter,
        heightFactor: isVisible ? 1 : 0,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: IgnorePointer(
          ignoring: !isVisible,
          child: ExcludeSemantics(excluding: !isVisible, child: child),
        ),
      ),
    );
  }
}
