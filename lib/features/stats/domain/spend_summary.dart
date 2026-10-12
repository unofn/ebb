import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../subscriptions/domain/money_total.dart';
import 'month_spend.dart';

/// Twelve months of spending at a glance, all in the base currency.
class SpendSummary {
  const SpendSummary({
    required this.total,
    required this.reimbursed,
    required this.peakIndex,
    required this.estimated,
  });

  /// What I paid (or will pay) myself; amounts without a rate kept apart.
  final MoneyTotal total;

  /// Reimbursed subscriptions, not in [total].
  final MoneyTotal reimbursed;

  /// The month with the most personal spending; null when all are zero.
  final int? peakIndex;

  /// Some month used today's rate instead of the recorded one.
  final bool estimated;

  /// [total] spread over the twelve months, rounded to the minor unit.
  int get averageMinor => (total.minor / 12).round();

  /// Currencies left out of either sum for want of a rate.
  Set<String> get missingRates => {
    ...total.unconverted.keys,
    ...reimbursed.unconverted.keys,
  };
}

/// Sums [months] (as from `pastMonths` or `futureMonths`), all in
/// [currency].
SpendSummary summarizeSpend(List<MonthSpend> months, String currency) {
  MoneyTotal add(Iterable<MoneyTotal> totals) {
    var minor = 0;
    final unconverted = <String, int>{};
    for (final t in totals) {
      minor += t.minor;
      for (final MapEntry(key: code, value: amount) in t.unconverted.entries) {
        unconverted[code] = (unconverted[code] ?? 0) + amount;
      }
    }
    return MoneyTotal(currency, minor, unconverted: unconverted);
  }

  int? peak;
  for (final (i, month) in months.indexed) {
    final best = peak == null ? 0 : months[peak].personal.minor;
    if (month.personal.minor > best) peak = i;
  }
  return SpendSummary(
    total: add(months.map((m) => m.personal)),
    reimbursed: add(months.map((m) => m.reimbursed)),
    peakIndex: peak,
    estimated: months.any((m) => m.estimated),
  );
}

/// Whether any charge of [subs] that the forecast counts (active, recurring)
/// is in a currency other than [base], so its total is approximate.
bool forecastConverts(Iterable<Subscription> subs, String base) => subs.any(
  (s) =>
      !s.deleted &&
      s.kind == SubscriptionKind.recurring &&
      s.status == SubscriptionStatus.active &&
      s.currency.toUpperCase() != base.toUpperCase(),
);
