import 'package:flutter/material.dart';

import '../../app/format/money_text.dart';
import '../../app/format/total_text.dart';
import '../../app/l10n/l10n.dart';
import '../../app/theme/ebb_colors.dart';
import '../../app/theme/ebb_type.dart';
import '../../app/widgets/fading_text.dart';
import '../billing/monthly_cost.dart';
import '../budget/domain/budget_status.dart';
import '../subscriptions/domain/home_totals.dart';
import '../subscriptions/domain/list_segments.dart';
import 'home_budget.dart';
import 'home_view.dart';

/// The average monthly cost in the base currency, stale rates flagged
/// beside it; the yearly equivalent (with the count when [withCount]);
/// amounts without a rate listed apart; the [budget] when given.
class HomeFigures extends StatelessWidget {
  const HomeFigures({
    super.key,
    required this.view,
    required this.today,
    this.withCount = false,
    this.budget,
  });

  final HomeView view;
  final DateTime today;
  final bool withCount;

  /// Shown at the end of the yearly line with a bar below; null hides it.
  final BudgetStatus? budget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final subs = view.subscriptions;
    final base = view.baseCurrency;
    final totals = homeTotals(
      subs,
      today: today,
      baseCurrency: base,
      rates: view.rates,
    );
    final converts = subs.any(
      (s) =>
          monthlyCostOf(s, today) != null &&
          s.currency.toUpperCase() != base.toUpperCase(),
    );
    final small = EbbType.small.tabular.copyWith(color: c.ink2);
    final unconverted = unconvertedText(l10n, totals.monthly);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            FadingText(
              moneyText(totals.monthly.minor, base),
              style: EbbType.large.tabular.copyWith(color: c.ink),
            ),
            if (converts && view.ratesOutdated)
              Text(
                l10n.homeRatesOutdated,
                style: small.copyWith(color: c.warn),
              ),
          ],
        ),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: Text(
                [
                  l10n.homeYearlyAbout(moneyText(totals.yearly.minor, base)),
                  if (withCount)
                    l10n.homeSubscriptionCount(
                      subscriptionsIn(ListSegment.all, subs).length,
                    ),
                ].join(' · '),
                style: small,
              ),
            ),
            if (budget case final status?)
              HomeBudgetText(status: status, currency: base),
          ],
        ),
        if (budget case final status?) HomeBudgetBar(status: status),
        if (unconverted.isNotEmpty)
          Text(l10n.homeUnconverted(unconverted), style: small),
      ],
    );
  }
}
