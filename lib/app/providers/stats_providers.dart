import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/home/home_view.dart';
import '../../features/stats/domain/breakdown_shares.dart';
import '../../features/stats/domain/future_months.dart';
import '../../features/stats/domain/month_spend.dart';
import '../../features/stats/domain/monthly_breakdown.dart';
import '../../features/stats/domain/past_months.dart';
import 'catalog_providers.dart';
import 'payment_providers.dart';

part 'stats_providers.g.dart';

// 统计和首页读同一份 homeView（订阅、基准货币、汇率），数字才对得上。
// [today] 由界面在 build 时取 `today()` 传入，跨天后自然换一份。

/// What was paid in each of the 12 months up to [today]'s.
@riverpod
Future<List<MonthSpend>> pastSpend(Ref ref, DateTime today) async {
  final view = await ref.watch(homeViewProvider.future);
  final payments = await ref.watch(allPaymentsProvider.future);
  return pastMonths(
    payments,
    view.subscriptions,
    today: today,
    rates: view.rates,
  );
}

/// What is expected in each of the 12 months from [today]'s.
@riverpod
Future<List<MonthSpend>> futureSpend(Ref ref, DateTime today) async {
  final view = await ref.watch(homeViewProvider.future);
  return futureMonths(
    view.subscriptions,
    today: today,
    rates: view.rates,
    base: view.baseCurrency,
  );
}

/// The home screen's monthly average by group and category.
@riverpod
Future<MonthlyBreakdown> costBreakdown(Ref ref, DateTime today) async {
  final view = await ref.watch(homeViewProvider.future);
  final categories = await ref.watch(categoriesProvider.future);
  return monthlyBreakdown(
    view.subscriptions,
    categories,
    today: today,
    rates: view.rates,
    base: view.baseCurrency,
  );
}
