import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/money.dart';

part 'exchange_rates.freezed.dart';

/// How many units of a currency one base unit buys; null when unknown.
typedef RateLookup = Decimal? Function(String currency);

/// Cached rates against [base]: 1 [base] = `rates[c]` units of `c`.
/// A user [overrides] entry wins over the fetched rate. Keys are uppercase
/// ISO 4217 codes.
@freezed
abstract class ExchangeRates with _$ExchangeRates {
  const factory ExchangeRates(
    String base, {
    @Default({}) Map<String, Decimal> rates,
    @Default({}) Map<String, Decimal> overrides,
  }) = _ExchangeRates;

  const ExchangeRates._();

  /// Units of [currency] per base unit (1 for the base itself).
  Decimal? rateOf(String currency) {
    final code = currency.toUpperCase();
    if (code == base.toUpperCase()) return Decimal.one;
    return overrides[code] ?? rates[code];
  }

  /// [amountMinor] of [from] in minor units of [to], rounded half up to
  /// [to]'s decimal digits; null when either rate is missing.
  int? convertMinor(int amountMinor, String from, String to) {
    if (from.toUpperCase() == to.toUpperCase()) return amountMinor;
    final fromRate = rateOf(from);
    final toRate = rateOf(to);
    if (fromRate == null || toRate == null || fromRate == Decimal.zero) {
      return null;
    }
    final fromDigits = currencyOf(from).decimalDigits;
    final toDigits = currencyOf(to).decimalDigits;
    final amount = Decimal.fromInt(amountMinor).shift(toDigits - fromDigits);
    // 全程有理数运算；Rational.round 远离零取整，正数即四舍五入。
    return (amount * toRate / fromRate).round().toInt();
  }
}
