import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/payment_providers.dart';
import '../../../app/providers/stats_providers.dart';
import '../../../app/widgets/content_width.dart';
import '../../../core/local_date.dart';
import '../../home/home_view.dart';
import '../domain/monthly_exclusions.dart';
import '../domain/nothing_to_chart.dart';
import 'breakdown_card.dart';
import 'review_card.dart';
import 'stats_budget_card.dart';
import 'stats_chart_section.dart';
import 'stats_chart_state.dart';
import 'stats_empty.dart';
import 'stats_header.dart';

/// Spending over the past or next twelve months, the monthly average by
/// group (the home screen's number), the budget and the quarterly review.
/// Phones stack them; from 840 the chart spans the width over a 3 : 2 row.
/// Before anything is paid or running, only the empty state.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= wideLayoutFrom;
    final now = today();
    final view = ref.watch(homeViewProvider).value;
    final breakdown = ref.watch(costBreakdownProvider(now)).value;
    final payments = ref.watch(allPaymentsProvider).value;
    if (view == null || breakdown == null || payments == null) {
      return const Scaffold();
    }
    if (nothingToChart(payments, view.subscriptions)) {
      return Scaffold(
        body: SafeArea(child: StatsEmpty(wide: wide)),
      );
    }
    final chart = ref.watch(statsChartStateProvider);
    final breakdownCard = BreakdownCard(
      breakdown: breakdown,
      exclusions: monthlyExclusions(view.subscriptions, now),
    );
    final budget = StatsBudgetCard(
      today: now,
      currency: view.baseCurrency,
      wide: wide,
    );
    final review = ReviewCard(today: now, wide: wide);
    final section = StatsChartSection(
      view: view,
      today: now,
      monthlyMinor: breakdown.total.minor,
      wide: wide,
    );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: wide
              ? const EdgeInsets.fromLTRB(40, 24, 40, 32)
              : const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            StatsHeader(range: chart.range, wide: wide),
            const SizedBox(height: 20),
            section,
            const SizedBox(height: 20),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 20,
                children: [
                  Expanded(flex: 3, child: breakdownCard),
                  Expanded(
                    flex: 2,
                    child: Column(spacing: 12, children: [budget, review]),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 20,
                children: [breakdownCard, budget, review],
              ),
          ],
        ),
      ),
    );
  }
}
