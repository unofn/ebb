import 'package:flutter/painting.dart';

/// The type scale: three sizes, two weights.
abstract final class EbbType {
  // 字族写进每个样式：DropdownButton 等控件直接用传入的样式，不与主题合并。
  static const family = 'IBM Plex Sans';
  static const fallback = ['Noto Sans SC'];

  /// Totals and page titles, 28/36.
  static const large = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.28,
  );

  /// Names and body text, 15/22.
  static const body = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 15,
    height: 22 / 15,
  );

  /// Secondary text and labels, 13/18.
  static const small = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 13,
    height: 18 / 13,
  );

  /// Status badges, 12/18.
  static const badge = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w600,
  );

  static const strong = FontWeight.w600;
}

extension Tabular on TextStyle {
  /// Equal-width digits, for amounts and dates.
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
