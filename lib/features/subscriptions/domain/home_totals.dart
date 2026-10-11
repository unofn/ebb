import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/database.dart';
import '../../billing/monthly_cost.dart';
import '../../rates/domain/exchange_rates.dart';
import 'money_total.dart';

part 'home_totals.freezed.dart';

/// The home screen's headline: average monthly cost and its yearly
/// equivalent (monthly × 12), both in the base currency.
@freezed
abstract class HomeTotals with _$HomeTotals {
  const factory HomeTotals({
    required MoneyTotal monthly,
    required MoneyTotal yearly,
  }) = _HomeTotals;
}

/// Σ [monthlyCostOf] over [subs] in [baseCurrency]; currencies without a
/// rate are listed in `unconverted` instead of being added.
HomeTotals homeTotals(
  Iterable<Subscription> subs, {
  required DateTime today,
  required String baseCurrency,
  required ExchangeRates rates,
}) {
  final monthly = sumIn(baseCurrency, [
    for (final sub in subs)
      if (monthlyCostOf(sub, today) case final minor?)
        (minor: minor, currency: sub.currency),
  ], rates);
  return HomeTotals(monthly: monthly, yearly: monthly * 12);
}
