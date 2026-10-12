import 'dart:math';

import '../../../core/money.dart';

/// [minor] units of [currency] as typed into the amount field: `400`,
/// `399.5`; empty for null.
String majorText(int? minor, String currency) {
  if (minor == null) return '';
  final digits = currencyOf(currency).decimalDigits;
  final unit = pow(10, digits).toInt();
  if (minor % unit == 0) return '${minor ~/ unit}';
  return (minor / unit)
      .toStringAsFixed(digits)
      .replaceFirst(RegExp(r'0+$'), '');
}

/// The typed [text] in minor units of [currency]; null unless it is an
/// amount above 0. Thousands separators are ignored.
int? parseBudget(String text, String currency) {
  final amount = double.tryParse(text.replaceAll(RegExp(r'[,\s]'), ''));
  if (amount == null || amount <= 0) return null;
  final minor = toMinor(amount, currency);
  return minor > 0 ? minor : null;
}
