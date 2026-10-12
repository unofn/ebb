import 'package:collection/collection.dart';

import '../../../data/database.dart';
import '../../rates/domain/exchange_rates.dart';
import '../../subscriptions/domain/money_total.dart';
import 'future_charges.dart';
import 'month_spend.dart';

/// The 12 months from this one on: [futureCharges] after [today] per month,
/// converted to [base] at today's [rates]; reimbursed subscriptions summed
/// apart.
List<MonthSpend> futureMonths(
  Iterable<Subscription> subs, {
  required DateTime today,
  required ExchangeRates rates,
  required String base,
}) {
  final months = monthsFrom(monthOf(today), 12);
  final charges = futureCharges(
    subs,
    today: today,
    untilExclusive: DateTime.utc(today.year, today.month + 12),
  );
  final byMonth = groupBy(charges, (FutureCharge c) => monthOf(c.date));
  MoneyTotal sum(List<FutureCharge> charges, {required bool reimbursed}) =>
      sumIn(base, [
        for (final c in charges)
          if (c.sub.reimbursed == reimbursed)
            (minor: c.amountMinor, currency: c.sub.currency),
      ], rates);
  return [
    for (final month in months)
      MonthSpend(
        month: month,
        personal: sum(byMonth[month] ?? const [], reimbursed: false),
        reimbursed: sum(byMonth[month] ?? const [], reimbursed: true),
      ),
  ];
}
