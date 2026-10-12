import '../../rates/domain/exchange_rates.dart';
import '../../subscriptions/domain/money_total.dart';
import 'calendar_charge.dart';

/// How many [charges] there are and their sum in [base] at today's
/// [rates]; [converted] when another currency went into the sum (the
/// calendar marks it 「≈」). Amounts without a rate stay in `unconverted`.
({int count, MoneyTotal total, bool converted}) chargeTotal(
  Iterable<CalendarCharge> charges,
  String base,
  ExchangeRates rates,
) {
  final list = charges.toList();
  return (
    count: list.length,
    total: sumIn(base, [
      for (final c in list) (minor: c.amountMinor, currency: c.currency),
    ], rates),
    converted: list.any(
      (c) =>
          c.currency.toUpperCase() != base.toUpperCase() &&
          rates.rateOf(c.currency) != null,
    ),
  );
}
