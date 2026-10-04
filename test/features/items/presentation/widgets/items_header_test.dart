import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/design_system/design_system.dart';
import 'package:hacker_pen/src/features/items/presentation/widgets/items_header.dart';

void main() {
  testWidgets('renders HackerPen editorial feed header', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var selectedTab = -1;
    var openedSettings = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: HpTheme.dark(),
        home: Scaffold(
          body: ItemsHeader(
            selectedTab: 0,
            tabs: const ['Top', 'New', 'Best', 'Ask', 'Show'],
            onTabSelected: (index) => selectedTab = index,
            onSettingsPressed: () => openedSettings = true,
          ),
        ),
      ),
    );

    expect(find.text('HACKERPEN'), findsOneWidget);
    expect(find.text('TOP STORIES'), findsNothing);
    expect(find.text('TOP'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);

    await tester.tap(find.text('ASK'));
    expect(selectedTab, 3);

    await tester.tap(find.byTooltip('Settings'));
    expect(openedSettings, isTrue);
  });
}
