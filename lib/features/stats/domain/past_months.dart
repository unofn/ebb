import '../../../data/database.dart';
import '../../payments/domain/payment_in_base.dart';
import '../../rates/domain/exchange_rates.dart';
import '../../subscriptions/domain/money_total.dart';
import 'month_spend.dart';

/// The 12 months up to and including this one: [payments] by the month of
/// their date, converted to `rates.base` by [paymentInBase] (at the rate
/// recorded with each; [MonthSpend.estimated] when one had to use today's).
/// Payments of reimbursed subscriptions (as marked now) are summed apart;
/// deleted payments and those of deleted subscriptions are left out.
List<MonthSpend> pastMonths(
  Iterable<Payment> payments,
  Iterable<Subscription> subs, {
  required DateTime today,
  required ExchangeRates rates,
}) {
  final months = monthsFrom(DateTime.utc(today.year, today.month - 11), 12);
  final live = {
    for (final sub in subs)
      if (!sub.deleted) sub.id: sub,
  };
  final buckets = {for (final month in months) month: _Bucket()};
  for (final payment in payments) {
    final sub = live[payment.subscriptionId];
    final bucket = buckets[monthOf(payment.paidOn)];
    if (payment.deleted || sub == null || bucket == null) continue;
    final sums = sub.reimbursed ? bucket.reimbursed : bucket.personal;
    switch (paymentInBase(payment, rates)) {
      case ConvertedAmount(:final minor, :final estimated):
        sums.minor += minor;
        bucket.estimated |= estimated;
      case MissingRate(:final currency):
        sums.unconverted[currency] =
            (sums.unconverted[currency] ?? 0) + payment.amountMinor;
    }
  }
  return [
    for (final MapEntry(key: month, value: bucket) in buckets.entries)
      MonthSpend(
        month: month,
        personal: bucket.personal.total(rates.base),
        reimbursed: bucket.reimbursed.total(rates.base),
        estimated: bucket.estimated,
      ),
  ];
}

class _Bucket {
  final personal = _Sums();
  final reimbursed = _Sums();
  var estimated = false;
}

class _Sums {
  var minor = 0;
  final unconverted = <String, int>{};

  MoneyTotal total(String currency) =>
      MoneyTotal(currency, minor, unconverted: unconverted);
}
