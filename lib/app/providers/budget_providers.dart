import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/budget/domain/budget_status.dart';
import '../../features/home/home_view.dart';
import '../../features/subscriptions/domain/home_totals.dart';
import 'repository_providers.dart';

part 'budget_providers.g.dart';

/// The monthly budget in minor units of the base currency; null when unset.
@riverpod
Stream<int?> monthlyBudget(Ref ref) =>
    ref.watch(localSettingsProvider).watchBudgetMonthlyMinor();

/// The home screen's monthly average (same inputs, same [homeTotals])
/// against the budget on [today]; null without a budget.
@riverpod
Future<BudgetStatus?> budgetStatusOn(Ref ref, DateTime today) async {
  final view = await ref.watch(homeViewProvider.future);
  final budget = await ref.watch(monthlyBudgetProvider.future);
  final totals = homeTotals(
    view.subscriptions,
    today: today,
    baseCurrency: view.baseCurrency,
    rates: view.rates,
  );
  return budgetStatus(totals.monthly.minor, budget);
}
