import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/design_system/design_system.dart';

void main() {
  test('light theme exposes Hacker News inspired tokens', () {
    final theme = HpTheme.light();
    final colors = theme.extension<HpColors>()!;
    final radii = theme.extension<HpRadii>()!;

    expect(colors.paper, const Color(0xFFF6F0DF));
    expect(colors.brand, const Color(0xFFFF6600));
    expect(radii.md, lessThanOrEqualTo(4));
    expect(theme.scaffoldBackgroundColor, colors.paper);
    expect(theme.colorScheme.primary, colors.brand);
  });

  testWidgets('context extensions resolve design tokens', (tester) async {
    late HpColors colors;
    late HpTypography typography;
    late HpSpacing spacing;

    await tester.pumpWidget(
      MaterialApp(
        theme: HpTheme.light(),
        home: Builder(
          builder: (context) {
            colors = context.hpColors;
            typography = context.hpText;
            spacing = context.hpSpacing;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(colors.brand, const Color(0xFFFF6600));
    expect(typography.monoFamily, isNotEmpty);
    expect(spacing.md, 12);
  });
}
