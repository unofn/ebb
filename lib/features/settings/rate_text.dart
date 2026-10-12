import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import '../../app/l10n/app_localizations.dart';

// 缓存里的汇率是「1 基准货币 = x 外币」；设计稿按「1 外币 = y 基准货币」
// 显示和录入（USD 7.10），两者互为倒数。

/// Base units one unit of a currency buys, from [perBase] (units of that
/// currency per base unit): 4 significant decimals at least 2, e.g.
/// `7.10`, `0.04695`.
String baseUnitsText(Decimal perBase) {
  final value = (Decimal.one / perBase)
      .toDecimal(scaleOnInfinitePrecision: 12)
      .toDouble();
  final leadingZeros = value >= 1 ? 0 : -(log(value) / ln10).floor() - 1;
  final decimals = min(10, max(2, 4 + leadingZeros));
  return NumberFormat('0.00${'#' * (decimals - 2)}', 'en_US').format(value);
}

/// The rate to store when the user says one unit of a currency buys
/// [baseUnits] (> 0) base units.
Decimal perBaseOf(Decimal baseUnits) =>
    (Decimal.one / baseUnits).toDecimal(scaleOnInfinitePrecision: 12);

/// When rates were fetched, in the device's time zone (an instant, not a
/// calendar day): 「今天 08:02」, else 「10月9日 08:02」.
String fetchedText(
  AppLocalizations l10n,
  String locale,
  DateTime fetchedAt,
  DateTime now,
) {
  final local = fetchedAt.toLocal();
  final today = now.toLocal();
  final time = DateFormat.Hm(locale).format(local);
  final sameDay =
      local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
  return sameDay
      ? l10n.settingsRatesToday(time)
      : '${DateFormat.MMMd(locale).format(local)} $time';
}
