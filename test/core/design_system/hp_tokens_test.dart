import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/design_system/design_system.dart';
import 'package:hacker_pen/src/core/theme/app_theme.dart';

void main() {
  test('token extensions copy and lerp values', () {
    const colors = HpColors.light;
    const red = Color(0xFFF44336);
    final changedColors = colors.copyWith(brand: red);
    expect(changedColors.brand, red);
    expect(colors.lerp(changedColors, 1).brand, red);

    const typography = HpTypography.light;
    expect(typography.copyWith(monoFamily: 'Mono').monoFamily, 'Mono');
    expect(
      typography.lerp(typography.copyWith(textFamily: 'Text'), 1).textFamily,
      'Text',
    );

    const spacing = HpSpacing.standard;
    expect(spacing.copyWith(md: 20).md, 20);
    expect(spacing.lerp(spacing.copyWith(md: 20), 0.5).md, 16);

    const radii = HpRadii.standard;
    expect(radii.copyWith(md: 3).medium, BorderRadius.circular(3));
    expect(radii.lerp(radii.copyWith(md: 8), 0.5).md, 6);

    const borders = HpBorders.standardBorders;
    expect(borders.copyWith(hairline: 2).hairline, 2);
    expect(borders.lerp(borders.copyWith(standard: 3), 0.5).standard, 2);
  });

  test('AppTheme compatibility wrapper delegates to HpTheme', () {
    expect(AppTheme.light().colorScheme.primary, HpColors.light.brand);
    expect(AppTheme.dark().scaffoldBackgroundColor, HpColors.light.paper);
  });
}
