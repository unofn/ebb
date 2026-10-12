import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/money.dart';
import '../../../data/database.dart';
import '../../rates/domain/exchange_rates.dart';

part 'payment_in_base.freezed.dart';

/// A payment in the current base currency, or why it is not.
@freezed
sealed class BaseAmount with _$BaseAmount {
  /// [minor] units of the base currency, rounded half up; [estimated] when
  /// today's rate took part (none recorded, or the base changed since).
  const factory BaseAmount.converted(
    int minor, {
    @Default(false) bool estimated,
  }) = ConvertedAmount;

  /// No rate for [currency] (uppercase, the payment's): left out of totals.
  const factory BaseAmount.missingRate(String currency) = MissingRate;
}

/// [payment] in `rates.base`, where [rates] are today's against it.
///
/// A payment in the base currency counts as is, exactly, whatever was
/// recorded. Else its amount ÷ the rate recorded with it gives the base
/// currency of that time: exact when that is still the base, else
/// converted on at today's rate. Without a recorded rate (or today's rate
/// for that old base) it is converted at today's rate. Anything at
/// today's rate is [ConvertedAmount.estimated]. Rounds once, at the end.
BaseAmount paymentInBase(Payment payment, ExchangeRates rates) {
  final currency = payment.currency.toUpperCase();
  final base = rates.base.toUpperCase();
  if (currency == base) return ConvertedAmount(payment.amountMinor);
  final digits =
      currencyOf(base).decimalDigits - currencyOf(currency).decimalDigits;
  final amount = Decimal.fromInt(payment.amountMinor).shift(digits);
  if (_recordedRate(payment) case (final rate, final oldBase)) {
    if (_positive(rates.rateOf(oldBase)) case final current?) {
      return ConvertedAmount(
        _divide(amount, rate * current),
        estimated: oldBase != base,
      );
    }
  }
  if (_positive(rates.rateOf(currency)) case final current?) {
    return ConvertedAmount(_divide(amount, current), estimated: true);
  }
  return MissingRate(currency);
}

/// The recorded rate and the base it is against, when both are usable.
(Decimal, String)? _recordedRate(Payment payment) {
  final rate = _positive(Decimal.tryParse(payment.rateToBase ?? ''));
  final oldBase = payment.baseCurrency?.toUpperCase();
  return rate == null || oldBase == null ? null : (rate, oldBase);
}

Decimal? _positive(Decimal? rate) =>
    rate == null || rate <= Decimal.zero ? null : rate;

// 有理数相除，只在最后取整；Rational.round 远离零取整，正数即四舍五入。
int _divide(Decimal amount, Decimal divisor) =>
    (amount / divisor).round().toInt();
