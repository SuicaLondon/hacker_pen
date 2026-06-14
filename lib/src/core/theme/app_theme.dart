import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

typedef AppPalette = HpColors;

extension AppThemeContext on BuildContext {
  AppPalette get palette => hpColors;
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => HpTheme.light();

  static ThemeData dark() => HpTheme.light();
}
