import '../../../../../core/money.dart';

final _amount = RegExp(r'^-?(\d+([.,]\d*)?|[.,]\d+)$');

/// [text] typed as a major-unit amount of [code] (`15.49`, `15,49`) in
/// minor units; null when blank or not a number.
int? parseMinor(String text, String code) {
  final trimmed = text.trim();
  if (!_amount.hasMatch(trimmed)) return null;
  return toMinor(double.parse(trimmed.replaceAll(',', '.')), code);
}

/// [minor] units of [code] as an input shows them: `1549` → `15.49`,
/// no symbol, no grouping.
String minorInput(int minor, String code) {
  final digits = currencyOf(code).decimalDigits;
  if (digits == 0) return '$minor';
  final sign = minor < 0 ? '-' : '';
  final text = minor.abs().toString().padLeft(digits + 1, '0');
  final cut = text.length - digits;
  return '$sign${text.substring(0, cut)}.${text.substring(cut)}';
}
