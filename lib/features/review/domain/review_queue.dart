import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../billing/cycle.dart';
import '../../billing/monthly_cost.dart';
import '../../rates/domain/exchange_rates.dart';
import '../../subscriptions/domain/name_order.dart';

part 'review_queue.freezed.dart';

/// A subscription to confirm in the quarterly review.
@freezed
abstract class ReviewItem with _$ReviewItem {
  const factory ReviewItem({
    required Subscription subscription,

    /// What it costs per month at the regular price (my share when
    /// shared), whether or not it counts toward the monthly average now;
    /// null without a known cycle.
    required int? monthlyMinor,

    /// The same in the base currency; null without a rate or cycle.
    required int? baseMinor,
  }) = _ReviewItem;
}

/// The active and paused recurring subscriptions, the most expensive per
/// month first (in [base]); those without an amount in [base] last, then
/// by name.
List<ReviewItem> reviewQueue(
  Iterable<Subscription> subs, {
  required ExchangeRates rates,
  required String base,
}) {
  final items = [
    for (final sub in subs)
      if (!sub.deleted &&
          sub.kind == SubscriptionKind.recurring &&
          (sub.status == SubscriptionStatus.active ||
              sub.status == SubscriptionStatus.paused))
        _itemOf(sub, rates, base),
  ];
  return items..sort(
    (a, b) => switch ((b.baseMinor ?? -1).compareTo(a.baseMinor ?? -1)) {
      0 => compareNames(a.subscription.name, b.subscription.name),
      final order => order,
    },
  );
}

ReviewItem _itemOf(Subscription sub, ExchangeRates rates, String base) {
  final cycle = sub.cycle;
  final monthly = cycle == null
      ? null
      : monthlyMinor(sub.myShareMinor ?? sub.priceMinor, cycle);
  return ReviewItem(
    subscription: sub,
    monthlyMinor: monthly,
    baseMinor: monthly == null
        ? null
        : rates.convertMinor(monthly, sub.currency, base),
  );
}
