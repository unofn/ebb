import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format/money_text.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/providers/stats_providers.dart';
import '../../home/home_view.dart';
import '../domain/spend_summary.dart';
import 'chart_card.dart';
import 'chart_texts.dart';
import 'stats_chart_state.dart';

/// The chart card for the chosen range: paid (this month counted only up
/// to today) or expected. The desktop adds the highest month and the home
/// monthly average beside the total.
class StatsChartSection extends ConsumerWidget {
  const StatsChartSection({
    super.key,
    required this.view,
    required this.today,
    required this.monthlyMinor,
    this.wide = false,
  });

  final HomeView view;
  final DateTime today;

  /// The home screen's monthly average.
  final int monthlyMinor;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final future =
        ref.watch(statsChartStateProvider).range == SpendRange.future;
    final months = future
        ? ref.watch(futureSpendProvider(today)).value
        : ref.watch(pastSpendProvider(today)).value;
    if (months == null) return const SizedBox.shrink();
    final base = view.baseCurrency;
    final texts = ChartTexts(
      l10n,
      months: months,
      summary: summarizeSpend(months, base),
      currency: base,
      approximate: future && forecastConverts(view.subscriptions, base),
      // 过去 12 个月的最后一根是当月，只算到今天。
      partialIndex: future ? null : months.length - 1,
    );
    return ChartCard(
      texts: texts,
      future: future,
      wide: wide,
      facts: [
        if (wide ? texts.peak : null case final peak?) (l10n.statsPeak, peak),
        if (wide) (l10n.statsVsHome, moneyText(monthlyMinor, base)),
      ],
    );
  }
}
