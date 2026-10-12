import 'package:collection/collection.dart';

import '../../../data/database.dart';
import '../../billing/monthly_cost.dart';
import '../../rates/domain/exchange_rates.dart';
import '../../subscriptions/domain/money_total.dart';
import 'breakdown_order.dart';
import 'breakdown_shares.dart';

typedef _Cost = ({Subscription sub, int minor});

/// [subs]' monthly average (as on the home screen: [monthlyCostOf], so
/// trials, ending, cancelled and reimbursed rows are left out) by group
/// and category. A subscription whose category is missing from
/// [categories] or deleted counts as uncategorized.
MonthlyBreakdown monthlyBreakdown(
  Iterable<Subscription> subs,
  Iterable<Category> categories, {
  required DateTime today,
  required ExchangeRates rates,
  required String base,
}) {
  final byId = {
    for (final c in categories)
      if (!c.deleted) c.id: c,
  };
  final costs = <_Cost>[
    for (final sub in subs)
      if (monthlyCostOf(sub, today) case final minor?) (sub: sub, minor: minor),
  ];
  MoneyTotal sum(Iterable<_Cost> costs) => sumIn(base, [
    for (final c in costs) (minor: c.minor, currency: c.sub.currency),
  ], rates);
  final total = sum(costs);
  double shareOf(int minor) => total.minor == 0 ? 0 : minor / total.minor;

  SubscriptionShare subscriptionShare(_Cost cost) {
    final inBase = rates.convertMinor(cost.minor, cost.sub.currency, base);
    return SubscriptionShare(
      subscription: cost.sub,
      monthlyMinor: cost.minor,
      baseMinor: inBase,
      share: shareOf(inBase ?? 0),
    );
  }

  CategoryShare categoryShare(Category? category, List<_Cost> costs) {
    final categoryTotal = sum(costs);
    return CategoryShare(
      category: category,
      total: categoryTotal,
      share: shareOf(categoryTotal.minor),
      subscriptions: costs.map(subscriptionShare).sorted(bySubscriptionSize),
    );
  }

  final byCategory = groupBy(costs, (_Cost c) => byId[c.sub.categoryId]?.id);
  final byGroup = groupBy(
    byCategory.keys,
    (String? id) => id == null ? null : byId[id]!.groupKey,
  );
  return MonthlyBreakdown(
    total: total,
    groups: [
      for (final MapEntry(key: group, value: ids) in byGroup.entries)
        _groupShare(
          group,
          [for (final id in ids) categoryShare(byId[id], byCategory[id]!)],
          total: sum([for (final id in ids) ...byCategory[id]!]),
          shareOf: shareOf,
        ),
    ].sorted(byGroupSize),
  );
}

GroupShare _groupShare(
  String? groupKey,
  List<CategoryShare> categories, {
  required MoneyTotal total,
  required double Function(int minor) shareOf,
}) => GroupShare(
  groupKey: groupKey,
  total: total,
  share: shareOf(total.minor),
  categories: categories.sorted(byCategorySize),
);
