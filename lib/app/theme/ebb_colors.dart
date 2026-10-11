import 'package:flutter/material.dart';

/// The design's color tokens; light and dark are tuned separately.
@immutable
class EbbColors extends ThemeExtension<EbbColors> {
  const EbbColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.accent,
    required this.accentSoft,
    required this.warn,
    required this.warnSoft,
    required this.danger,
    required this.tabOn,
    required this.mark,
  });

  static const light = EbbColors(
    bg: Color(0xFFF5F5F3),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEEEFF1),
    line: Color(0xFFE6E7EA),
    lineStrong: Color(0xFFD3D5DA),
    ink: Color(0xFF15171C),
    ink2: Color(0xFF5A606C),
    ink3: Color(0xFF6E7480),
    accent: Color(0xFF0B6E69),
    accentSoft: Color(0xFFE3F1EF),
    warn: Color(0xFFA4540A),
    warnSoft: Color(0xFFFBF0E1),
    danger: Color(0xFFB3261E),
    tabOn: Color(0xFFFFFFFF),
    mark: Color(0xFFC9CCD2),
  );

  static const dark = EbbColors(
    bg: Color(0xFF0F1012),
    surface: Color(0xFF17191C),
    surface2: Color(0xFF1F2125),
    line: Color(0xFF2A2D32),
    lineStrong: Color(0xFF3A3E44),
    ink: Color(0xFFECEDEF),
    ink2: Color(0xFFA3A8B2),
    ink3: Color(0xFF868C97),
    accent: Color(0xFF4CC2B5),
    accentSoft: Color(0xFF12302D),
    warn: Color(0xFFE9A23B),
    warnSoft: Color(0xFF33240F),
    danger: Color(0xFFF2766B),
    tabOn: Color(0xFF2A2D32),
    mark: Color(0xFF4A4E55),
  );

  final Color bg, surface, surface2, line, lineStrong, ink, ink2, ink3;
  final Color accent, accentSoft, warn, warnSoft, danger;

  /// The selected segment's block.
  final Color tabOn;

  /// The empty-state illustration's untinted lines.
  final Color mark;

  @override
  EbbColors copyWith() => this;

  @override
  EbbColors lerp(EbbColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return EbbColors(
      bg: mix(bg, other.bg),
      surface: mix(surface, other.surface),
      surface2: mix(surface2, other.surface2),
      line: mix(line, other.line),
      lineStrong: mix(lineStrong, other.lineStrong),
      ink: mix(ink, other.ink),
      ink2: mix(ink2, other.ink2),
      ink3: mix(ink3, other.ink3),
      accent: mix(accent, other.accent),
      accentSoft: mix(accentSoft, other.accentSoft),
      warn: mix(warn, other.warn),
      warnSoft: mix(warnSoft, other.warnSoft),
      danger: mix(danger, other.danger),
      tabOn: mix(tabOn, other.tabOn),
      mark: mix(mark, other.mark),
    );
  }
}

extension EbbColorsOf on BuildContext {
  EbbColors get colors => Theme.of(this).extension<EbbColors>()!;
}
