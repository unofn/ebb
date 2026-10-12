import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../billing/cycle.dart';
import '../../payments/domain/billing_anchor.dart';
import '../../subscriptions/domain/amount_due.dart';

/// A charge expected on [date], in the subscription's own currency.
typedef FutureCharge = ({Subscription sub, DateTime date, int amountMinor});

/// Charges [subs] are expected to make after [today] (and from [from] on,
/// when later) before [untilExclusive], shared by the 12-month forecast
/// and the calendar.
///
/// Only active and ending recurring rows count (auto and manual renewal
/// alike), an ending one only before its end date, as the automatic
/// payments do; paused, cancelled and one-time rows do not. Occurrences are
/// counted from the billing anchor (as the automatic payments are), from
/// next_date on (the trial end when there is none); days in a trial charge
/// nothing ([amountFor]), so a trial counts from its end.
Iterable<FutureCharge> futureCharges(
  Iterable<Subscription> subs, {
  required DateTime today,
  required DateTime untilExclusive,
  DateTime? from,
}) sync* {
  final tomorrow = today.add(const Duration(days: 1));
  final earliest = from != null && from.isAfter(tomorrow) ? from : tomorrow;
  final through = untilExclusive.subtract(const Duration(days: 1));
  for (final sub in subs) {
    final cycle = sub.cycle;
    final ending = sub.status == SubscriptionStatus.ending;
    final endDate = ending ? sub.endDate : null;
    final start = sub.nextDate ?? (ending ? null : sub.trialEndsOn);
    if (sub.deleted ||
        sub.kind != SubscriptionKind.recurring ||
        !(ending || sub.status == SubscriptionStatus.active) ||
        cycle == null ||
        start == null) {
      continue;
    }
    final anchor = billingAnchor(sub, cycle) ?? start;
    final first = start.isAfter(earliest) ? start : earliest;
    for (final date in dueDates(anchor, cycle, from: first, through: through)) {
      if (endDate != null && !date.isBefore(endDate)) break;
      if (amountFor(sub, date) case final amount?) {
        yield (sub: sub, date: date, amountMinor: amount);
      }
    }
  }
}
