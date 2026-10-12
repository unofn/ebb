import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/format/money_text.dart';
import '../../app/format/total_text.dart';
import '../../app/l10n/l10n.dart';
import '../../app/router/route_paths.dart';
import '../../app/theme/ebb_colors.dart';
import '../../app/theme/ebb_type.dart';
import '../billing/monthly_cost.dart';
import '../subscriptions/domain/home_totals.dart';
import '../subscriptions/domain/list_segments.dart';
import 'home_view.dart';

/// The headline: average monthly cost in the base currency and its
/// yearly equivalent; amounts without a rate are listed apart, and stale
/// rates are flagged beside the number.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.view, required this.today});

  final HomeView view;
  final DateTime today;

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
    final count = subscriptionsIn(ListSegment.all, subs).length;
    final unconverted = unconvertedText(l10n, totals.monthly);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Row(
          children: [
            Expanded(child: Text(l10n.homeMonthlyAverage, style: small)),
            IconButton.filled(
              tooltip: l10n.homeAdd,
              style: IconButton.styleFrom(
                backgroundColor: c.ink,
                foregroundColor: c.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => context.push(RoutePaths.newSubscription),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: 8,
          children: [
            Text(
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
        Text(
          [
            l10n.homeYearlyAbout(moneyText(totals.yearly.minor, base)),
            l10n.homeSubscriptionCount(count),
          ].join(' · '),
          style: small,
        ),
        if (unconverted.isNotEmpty)
          Text(l10n.homeUnconverted(unconverted), style: small),
      ],
    );
  }
}
