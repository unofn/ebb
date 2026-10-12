import 'dart:math';

import '../../../core/money.dart';

/// Quick amounts for the budget sheet, in minor units of [currency]: the
/// monthly average [monthlyMinor] rounded up to a round step, the next
/// two steps, and a roomier round amount. Without an average: 100, 200,
/// 300 and 500.
List<int> budgetPresets(int monthlyMinor, String currency) {
  final unit = pow(10, currencyOf(currency).decimalDigits).toInt();
  if (monthlyMinor <= 0) {
    return [
      for (final v in [100, 200, 300, 500]) v * unit,
    ];
  }
  final major = monthlyMinor / unit;
  final magnitude = max(1, pow(10, (log(major) / ln10).floor()).toInt());
  // 3.18 百 → 步长 50；8.7 十 → 步长 10。
  final step = max(1, major / magnitude < 5 ? magnitude ~/ 2 : magnitude);
  final first = (major / step).ceil() * step;
  final third = first + 2 * step;
  final roomy = (third * 1.25 / (2 * step)).ceil() * 2 * step;
  return [
    for (final v in [first, first + step, third, roomy]) v * unit,
  ];
}
