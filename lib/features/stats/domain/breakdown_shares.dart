import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/database.dart';
import '../../subscriptions/domain/money_total.dart';

part 'breakdown_shares.freezed.dart';

// share 都是占月均合计（基准货币）的比例，0–1；缺汇率的金额不计入，占比为 0。

/// The monthly average split by statistics group, then category, then
/// subscription; largest first at every level.
@freezed
abstract class MonthlyBreakdown with _$MonthlyBreakdown {
  const factory MonthlyBreakdown({
    /// Equals the home screen's monthly total.
    required MoneyTotal total,
    required List<GroupShare> groups,
  }) = _MonthlyBreakdown;
}

@freezed
abstract class GroupShare with _$GroupShare {
  const factory GroupShare({
    /// Statistics group key (`software`, …); null for uncategorized.
    required String? groupKey,
    required MoneyTotal total,
    required double share,
    required List<CategoryShare> categories,
  }) = _GroupShare;
}

@freezed
abstract class CategoryShare with _$CategoryShare {
  const factory CategoryShare({
    /// Null in the uncategorized group.
    required Category? category,
    required MoneyTotal total,
    required double share,
    required List<SubscriptionShare> subscriptions,
  }) = _CategoryShare;
}

@freezed
abstract class SubscriptionShare with _$SubscriptionShare {
  const factory SubscriptionShare({
    required Subscription subscription,

    /// Monthly cost in the subscription's own currency.
    required int monthlyMinor,

    /// The same in the base currency; null without a rate.
    required int? baseMinor,
    required double share,
  }) = _SubscriptionShare;
}
