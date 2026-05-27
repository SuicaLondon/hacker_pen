import 'package:flutter/material.dart';

import 'app_fonts.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.backgroundElevated,
    required this.surface,
    required this.commentSurface,
    required this.commentSurfaceAlt,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.brandOrange,
  });

  static const dark = AppPalette(
    background: Color(0xFF090909),
    backgroundElevated: Color(0xFF0B0B0B),
    surface: Color(0xFF121212),
    commentSurface: Color(0xFF111111),
    commentSurfaceAlt: Color(0xFF161616),
    divider: Color(0xFF1F1F1F),
    textPrimary: Colors.white,
    textSecondary: Color(0xFF8E8E93),
    textMuted: Color(0xFFB6B6B6),
    brandOrange: Color(0xFFFF6600),
  );

  final Color background;
  final Color backgroundElevated;
  final Color surface;
  final Color commentSurface;
  final Color commentSurfaceAlt;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color brandOrange;

  @override
  AppPalette copyWith({
    Color? background,
    Color? backgroundElevated,
    Color? surface,
    Color? commentSurface,
    Color? commentSurfaceAlt,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? brandOrange,
  }) {
    return AppPalette(
      background: background ?? this.background,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      surface: surface ?? this.surface,
      commentSurface: commentSurface ?? this.commentSurface,
      commentSurfaceAlt: commentSurfaceAlt ?? this.commentSurfaceAlt,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      brandOrange: brandOrange ?? this.brandOrange,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;

    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      backgroundElevated: Color.lerp(
        backgroundElevated,
        other.backgroundElevated,
        t,
      )!,
      surface: Color.lerp(surface, other.surface, t)!,
      commentSurface: Color.lerp(commentSurface, other.commentSurface, t)!,
      commentSurfaceAlt: Color.lerp(
        commentSurfaceAlt,
        other.commentSurfaceAlt,
        t,
      )!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      brandOrange: Color.lerp(brandOrange, other.brandOrange, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    const palette = AppPalette.dark;

    return ThemeData(
      fontFamily: AppFonts.text,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.background,
      dividerColor: palette.divider,
      colorScheme: ColorScheme.dark(
        primary: palette.brandOrange,
        surface: palette.surface,
        surfaceContainer: palette.backgroundElevated,
        surfaceContainerLow: palette.commentSurface,
        surfaceContainerHigh: palette.commentSurfaceAlt,
        onSurface: palette.textPrimary,
        onSurfaceVariant: palette.textSecondary,
        outline: palette.divider,
        outlineVariant: palette.textMuted,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.backgroundElevated,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? palette.brandOrange : palette.textSecondary,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? palette.brandOrange : palette.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          );
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.brandOrange,
      ),
      dividerTheme: DividerThemeData(color: palette.divider, thickness: 1),
      extensions: const [palette],
    );
  }
}
