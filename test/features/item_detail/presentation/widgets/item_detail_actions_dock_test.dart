import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/design_system/design_system.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/widgets/item_detail_actions_dock.dart';

void main() {
  testWidgets(
    'scroll activity collapses actions again after manual expansion',
    (tester) async {
      final scrollActivity = ValueNotifier(0);
      addTearDown(scrollActivity.dispose);
      await _pumpDock(tester, scrollActivity);
      final dock = find.byType(ItemDetailActionsDock);
      final expandedWidth = tester.getSize(dock).width;
      final action = find.text('SUMMARY');

      scrollActivity.value++;
      await tester.pumpAndSettle();
      expect(tester.getSize(dock).width, 14);
      expect(action.hitTestable(), findsNothing);
      expect(find.byType(Icon), findsNothing);
      await tester.tap(dock);
      await tester.pumpAndSettle();
      expect(tester.getSize(dock).width, 14);

      final gesture = await tester.startGesture(tester.getCenter(dock));
      await gesture.moveBy(const Offset(-30, 0));
      await gesture.moveBy(const Offset(-35, 0));
      await tester.pump();
      expect(tester.getSize(dock).width, greaterThan(14));
      expect(tester.getSize(dock).width, lessThan(expandedWidth));
      await gesture.moveBy(const Offset(-160, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getSize(dock).width, expandedWidth);
      expect(action.hitTestable(), findsOneWidget);

      await tester.pumpAndSettle();
      expect(tester.getSize(dock).width, expandedWidth);

      await tester.drag(action, const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(tester.getSize(dock).width, 14);
      await tester.drag(dock, const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(action.hitTestable(), findsOneWidget);
      scrollActivity.value++;
      await tester.pumpAndSettle();
      expect(action.hitTestable(), findsNothing);
    },
  );

  testWidgets(
    'collapsed actions release page taps and stay above safe insets',
    (tester) async {
      final scrollActivity = ValueNotifier(0);
      addTearDown(scrollActivity.dispose);
      var pageTaps = 0;
      var actionTaps = 0;
      await _pumpDock(
        tester,
        scrollActivity,
        onPageTap: () => pageTaps++,
        onActionTap: () => actionTaps++,
        padding: const EdgeInsets.only(left: 34, right: 34, bottom: 34),
      );
      final dock = find.byType(ItemDetailActionsDock);
      final actionPosition = tester.getCenter(find.text('SUMMARY'));
      await tester.tapAt(actionPosition);
      expect(actionTaps, 1);

      scrollActivity.value++;
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final bounds = tester.getRect(dock);
        expect(bounds.right, closeTo(390 - 34, 0.01));
        expect(bounds.bottom, closeTo(844 - 34 - 16, 0.01));
      }
      await tester.tapAt(actionPosition);
      expect(pageTaps, 1);
      expect(actionTaps, 1);
      await tester.drag(
        find.byType(ItemDetailActionsDock),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('SUMMARY').hitTestable(), findsOneWidget);
    },
  );

  testWidgets(
    'swipe-only edge works with reduced motion and excludes hidden actions',
    (tester) async {
      final scrollActivity = ValueNotifier(0);
      addTearDown(scrollActivity.dispose);
      final semantics = tester.ensureSemantics();

      try {
        await _pumpDock(tester, scrollActivity, disableAnimations: true);
        scrollActivity.value++;
        await tester.pump();
        expect(find.bySemanticsLabel('Reading actions'), findsOneWidget);
        expect(find.byType(InkWell).hitTestable(), findsNothing);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Reading actions'))
              .childrenCount,
          0,
        );
        await tester.drag(
          find.byType(ItemDetailActionsDock),
          const Offset(-200, 0),
        );
        await tester.pump();
        expect(find.text('SUMMARY').hitTestable(), findsOneWidget);
        await tester.drag(find.text('SUMMARY'), const Offset(200, 0));
        await tester.pump();
        expect(tester.getSize(find.byType(ItemDetailActionsDock)).width, 14);
      } finally {
        semantics.dispose();
      }
    },
  );
}

Future<void> _pumpDock(
  WidgetTester tester,
  ValueNotifier<int> scrollActivity, {
  VoidCallback? onPageTap,
  VoidCallback? onActionTap,
  EdgeInsets padding = const EdgeInsets.only(bottom: 34),
  bool disableAnimations = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: HpTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          padding: padding,
          viewPadding: padding,
          disableAnimations: disableAnimations,
        ),
        child: ValueListenableBuilder(
          valueListenable: scrollActivity,
          builder: (context, _, _) => Scaffold(
            floatingActionButtonLocation: ItemDetailActionsDock.location,
            floatingActionButtonAnimator:
                FloatingActionButtonAnimator.noAnimation,
            floatingActionButton: ItemDetailActionsDock(
              scrollActivity: scrollActivity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: onActionTap ?? () {},
                    child: const Text('SUMMARY'),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('12 COMMENTS'),
                  ),
                ],
              ),
            ),
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPageTap,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
