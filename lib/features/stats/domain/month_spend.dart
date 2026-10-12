import 'package:freezed_annotation/freezed_annotation.dart';

import '../../subscriptions/domain/money_total.dart';

part 'month_spend.freezed.dart';

/// One calendar month of spending in the base currency: what I pay myself
/// and what is reimbursed, kept apart.
@freezed
abstract class MonthSpend with _$MonthSpend {
  const factory MonthSpend({
    /// The month's first day (UTC midnight).
    required DateTime month,
    required MoneyTotal personal,
    required MoneyTotal reimbursed,

    /// Some amount was converted at today's rate, not the one recorded
    /// with the payment.
    @Default(false) bool estimated,
  }) = _MonthSpend;

  const MonthSpend._();

  /// Currencies left out of the totals for want of a rate.
  Set<String> get missingRates => {
    ...personal.unconverted.keys,
    ...reimbursed.unconverted.keys,
  };
}

/// The first day of [count] consecutive months starting with [first]'s.
List<DateTime> monthsFrom(DateTime first, int count) => [
  for (var i = 0; i < count; i++) DateTime.utc(first.year, first.month + i),
];

/// The first day of [date]'s month.
DateTime monthOf(DateTime date) => DateTime.utc(date.year, date.month);
