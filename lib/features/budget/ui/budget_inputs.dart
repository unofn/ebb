import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/budget_providers.dart';
import '../../billing/monthly_cost.dart';
import '../../home/home_view.dart';
import '../../subscriptions/domain/home_totals.dart';
import '../../subscriptions/domain/money_total.dart';

part 'budget_inputs.g.dart';

/// What the budget sheet compares against: the home screen's monthly
/// average and the saved budget.
class BudgetInputs {
  const BudgetInputs({
    required this.monthly,
    required this.converted,
    required this.budget,
  });

  /// In the base currency, as on the home screen.
  final MoneyTotal monthly;

  /// Other currencies went into [monthly] at today's rates.
  final bool converted;

  /// Minor units of the base currency; null when unset.
  final int? budget;

  String get currency => monthly.currency;
}

@riverpod
Future<BudgetInputs> budgetInputs(Ref ref, DateTime today) async {
  final view = await ref.watch(homeViewProvider.future);
  final base = view.baseCurrency;
  return BudgetInputs(
    monthly: homeTotals(
      view.subscriptions,
      today: today,
      baseCurrency: base,
      rates: view.rates,
    ).monthly,
    converted: view.subscriptions.any(
      (s) =>
          monthlyCostOf(s, today) != null &&
          s.currency.toUpperCase() != base.toUpperCase(),
    ),
    budget: await ref.watch(monthlyBudgetProvider.future),
  );
}
