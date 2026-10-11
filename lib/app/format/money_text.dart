import 'dart:math';

import 'package:intl/intl.dart';

import '../../core/money.dart';

/// [minor] units of [code] as the design writes amounts: symbol first,
/// thousands commas, the currency's decimals (`¥1,234.50`, `$15.49`).
/// Currencies without a known symbol show their code (`ABC 15.00`).
String moneyText(int minor, String code) {
  final currency = currencyOf(code);
  final digits = currency.decimalDigits;
  // 不跟随语言：设计规定千分位逗号、小数点。
  final number = NumberFormat.decimalPatternDigits(
    locale: 'en_US',
    decimalDigits: digits,
  ).format(minor / pow(10, digits));
  return isKnownCurrency(code)
      ? '${currency.symbol}$number'
      : '${code.toUpperCase()} $number';
}
