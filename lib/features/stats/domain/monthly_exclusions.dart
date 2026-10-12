import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../billing/monthly_cost.dart';
import '../../subscriptions/domain/name_order.dart';
import '../../subscriptions/domain/subscription_state.dart';

/// Why a running subscription is left out of the monthly average.
enum ExclusionReason { paused, ending, trial, reimbursed }

typedef MonthlyExclusion = ({Subscription sub, ExclusionReason reason});

/// The recurring subscriptions [monthlyCostOf] leaves out on [today]
/// (archived and one-time ones aside), each with its reason, by name: the
/// note under the breakdown.
List<MonthlyExclusion> monthlyExclusions(
  Iterable<Subscription> subs,
  DateTime today,
) => [
  for (final sub in subs)
    if (!sub.deleted &&
        sub.kind == SubscriptionKind.recurring &&
        sub.status != SubscriptionStatus.cancelled &&
        monthlyCostOf(sub, today) == null)
      if (_reasonOf(sub, today) case final reason?) (sub: sub, reason: reason),
]..sort((a, b) => compareNames(a.sub.name, b.sub.name));

ExclusionReason? _reasonOf(Subscription sub, DateTime today) =>
    switch (sub.status) {
      SubscriptionStatus.paused => ExclusionReason.paused,
      SubscriptionStatus.ending => ExclusionReason.ending,
      _ when sub.isInTrial(today) => ExclusionReason.trial,
      _ when sub.reimbursed => ExclusionReason.reimbursed,
      // 没有周期的不计入，但说不出原因，不列。
      _ => null,
    };
