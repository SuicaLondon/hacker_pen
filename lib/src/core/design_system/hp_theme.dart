import 'package:flutter/material.dart';

import 'hp_tokens.dart';

class HpTheme {
  const HpTheme._();

  static ThemeData light() {
    const colors = HpColors.light;
    const typography = HpTypography.light;

    final baseTextTheme =
        TextTheme(
          displaySmall: TextStyle(
            fontFamily: typography.displayFamily,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: 0,
          ),
          titleLarge: TextStyle(
            fontFamily: typography.displayFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: 0,
          ),
          titleMedium: TextStyle(
            fontFamily: typography.textFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: 0,
          ),
          titleSmall: TextStyle(
            fontFamily: typography.textFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: 0,
          ),
          bodyLarge: TextStyle(
            fontFamily: typography.textFamily,
            fontSize: 17,
            fontWeight: FontWeight.w400,
            height: 1.42,
            letterSpacing: 0,
          ),
          bodyMedium: TextStyle(
            fontFamily: typography.textFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.32,
            letterSpacing: 0,
          ),
          bodySmall: TextStyle(
            fontFamily: typography.textFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.22,
            letterSpacing: 0,
          ),
          labelLarge: TextStyle(
            fontFamily: typography.monoFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: 0,
          ),
          labelMedium: TextStyle(
            fontFamily: typography.monoFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: 0,
          ),
          labelSmall: TextStyle(
            fontFamily: typography.monoFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.1,
            letterSpacing: 0,
          ),
        ).apply(
          bodyColor: colors.ink,
          displayColor: colors.ink,
          decorationColor: colors.ink,
        );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(HpRadii.standard.md),
      borderSide: BorderSide(color: colors.rule),
    );

    return ThemeData(
      useMaterial3: false,
      fontFamily: typography.textFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.paper,
      dividerColor: colors.rule,
      textTheme: baseTextTheme,
      colorScheme: ColorScheme.light(
        primary: colors.brand,
        secondary: colors.brand,
        surface: colors.surface,
        onSurface: colors.ink,
        onSurfaceVariant: colors.inkMuted,
        outline: colors.rule,
        outlineVariant: colors.ruleStrong,
        error: colors.danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.paper,
        foregroundColor: colors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: baseTextTheme.titleMedium,
        iconTheme: IconThemeData(color: colors.ink, size: 20),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
      ),
      buttonTheme: const ButtonThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.brand,
          foregroundColor: colors.surface,
          elevation: 0,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HpRadii.standard.md),
          ),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brand,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brand,
          foregroundColor: colors.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HpRadii.standard.md),
          ),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.ruleStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HpRadii.standard.md),
          ),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        labelStyle: baseTextTheme.bodySmall?.copyWith(color: colors.inkMuted),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(color: colors.inkSubtle),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.brand),
        ),
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.rule.withValues(alpha: 0.55)),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.danger),
        ),
      ),
      iconTheme: IconThemeData(color: colors.inkMuted, size: 18),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.brand,
        linearTrackColor: colors.rule,
      ),
      dividerTheme: DividerThemeData(
        color: colors.rule,
        thickness: 0.75,
        space: 0.75,
      ),
      extensions: const [
        colors,
        typography,
        HpSpacing.standard,
        HpRadii.standard,
        HpBorders.standardBorders,
      ],
    );
  }
}
