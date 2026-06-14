import 'package:flutter/material.dart';

@immutable
class HpColors extends ThemeExtension<HpColors> {
  const HpColors({
    required this.paper,
    required this.paperAlt,
    required this.surface,
    required this.surfaceMuted,
    required this.highlight,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.rule,
    required this.ruleStrong,
    required this.brand,
    required this.danger,
  });

  static const light = HpColors(
    paper: Color(0xFFF6F0DF),
    paperAlt: Color(0xFFF1E6CE),
    surface: Color(0xFFFFFBF0),
    surfaceMuted: Color(0xFFF9EBD4),
    highlight: Color(0xFFFFF0D9),
    ink: Color(0xFF1D1D1B),
    inkMuted: Color(0xFF625E55),
    inkSubtle: Color(0xFF8A8375),
    rule: Color(0xFFD8CBB6),
    ruleStrong: Color(0xFFBBAA8F),
    brand: Color(0xFFFF6600),
    danger: Color(0xFFB3261E),
  );

  final Color paper;
  final Color paperAlt;
  final Color surface;
  final Color surfaceMuted;
  final Color highlight;
  final Color ink;
  final Color inkMuted;
  final Color inkSubtle;
  final Color rule;
  final Color ruleStrong;
  final Color brand;
  final Color danger;

  @override
  HpColors copyWith({
    Color? paper,
    Color? paperAlt,
    Color? surface,
    Color? surfaceMuted,
    Color? highlight,
    Color? ink,
    Color? inkMuted,
    Color? inkSubtle,
    Color? rule,
    Color? ruleStrong,
    Color? brand,
    Color? danger,
  }) {
    return HpColors(
      paper: paper ?? this.paper,
      paperAlt: paperAlt ?? this.paperAlt,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      highlight: highlight ?? this.highlight,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkSubtle: inkSubtle ?? this.inkSubtle,
      rule: rule ?? this.rule,
      ruleStrong: ruleStrong ?? this.ruleStrong,
      brand: brand ?? this.brand,
      danger: danger ?? this.danger,
    );
  }

  @override
  HpColors lerp(ThemeExtension<HpColors>? other, double t) {
    if (other is! HpColors) return this;

    return HpColors(
      paper: Color.lerp(paper, other.paper, t)!,
      paperAlt: Color.lerp(paperAlt, other.paperAlt, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkSubtle: Color.lerp(inkSubtle, other.inkSubtle, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      ruleStrong: Color.lerp(ruleStrong, other.ruleStrong, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

@immutable
class HpTypography extends ThemeExtension<HpTypography> {
  const HpTypography({
    required this.textFamily,
    required this.displayFamily,
    required this.monoFamily,
  });

  static const light = HpTypography(
    textFamily: '.SF Pro Text',
    displayFamily: '.SF Pro Display',
    monoFamily: 'Menlo',
  );

  final String textFamily;
  final String displayFamily;
  final String monoFamily;

  @override
  HpTypography copyWith({
    String? textFamily,
    String? displayFamily,
    String? monoFamily,
  }) {
    return HpTypography(
      textFamily: textFamily ?? this.textFamily,
      displayFamily: displayFamily ?? this.displayFamily,
      monoFamily: monoFamily ?? this.monoFamily,
    );
  }

  @override
  HpTypography lerp(ThemeExtension<HpTypography>? other, double t) {
    if (other is! HpTypography) return this;
    return t < 0.5 ? this : other;
  }
}

@immutable
class HpSpacing extends ThemeExtension<HpSpacing> {
  const HpSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  static const standard = HpSpacing(xs: 4, sm: 8, md: 12, lg: 16, xl: 24);

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  @override
  HpSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) {
    return HpSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  HpSpacing lerp(ThemeExtension<HpSpacing>? other, double t) {
    if (other is! HpSpacing) return this;

    return HpSpacing(
      xs: lerpDouble(xs, other.xs, t),
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

@immutable
class HpRadii extends ThemeExtension<HpRadii> {
  const HpRadii({required this.none, required this.sm, required this.md});

  static const standard = HpRadii(none: 0, sm: 2, md: 4);

  final double none;
  final double sm;
  final double md;

  BorderRadius get small => BorderRadius.circular(sm);

  BorderRadius get medium => BorderRadius.circular(md);

  @override
  HpRadii copyWith({double? none, double? sm, double? md}) {
    return HpRadii(
      none: none ?? this.none,
      sm: sm ?? this.sm,
      md: md ?? this.md,
    );
  }

  @override
  HpRadii lerp(ThemeExtension<HpRadii>? other, double t) {
    if (other is! HpRadii) return this;
    return HpRadii(
      none: HpSpacing.lerpDouble(none, other.none, t),
      sm: HpSpacing.lerpDouble(sm, other.sm, t),
      md: HpSpacing.lerpDouble(md, other.md, t),
    );
  }
}

@immutable
class HpBorders extends ThemeExtension<HpBorders> {
  const HpBorders({required this.hairline, required this.standard});

  static const standardBorders = HpBorders(hairline: 0.75, standard: 1);

  final double hairline;
  final double standard;

  @override
  HpBorders copyWith({double? hairline, double? standard}) {
    return HpBorders(
      hairline: hairline ?? this.hairline,
      standard: standard ?? this.standard,
    );
  }

  @override
  HpBorders lerp(ThemeExtension<HpBorders>? other, double t) {
    if (other is! HpBorders) return this;
    return HpBorders(
      hairline: HpSpacing.lerpDouble(hairline, other.hairline, t),
      standard: HpSpacing.lerpDouble(standard, other.standard, t),
    );
  }
}

extension HpDesignContext on BuildContext {
  HpColors get hpColors => Theme.of(this).extension<HpColors>()!;

  HpTypography get hpText => Theme.of(this).extension<HpTypography>()!;

  HpSpacing get hpSpacing => Theme.of(this).extension<HpSpacing>()!;

  HpRadii get hpRadii => Theme.of(this).extension<HpRadii>()!;

  HpBorders get hpBorders => Theme.of(this).extension<HpBorders>()!;
}
