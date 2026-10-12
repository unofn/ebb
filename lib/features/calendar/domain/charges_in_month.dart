import '../../../core/local_date.dart';
import '../../../data/database.dart';
import '../../stats/domain/future_charges.dart';
import '../../subscriptions/domain/amount_due.dart';
import '../../subscriptions/domain/name_order.dart';
import '../../subscriptions/domain/subscription_state.dart';
import 'calendar_charge.dart';

/// The charges in [year]-[month] by day of month (days without any left
/// out), each day ordered by [ChargeKind], then subscription name.
///
/// - Paid: every payment in the month, including one confirmed ahead of
///   its date; deleted payments and those of deleted subscriptions are
///   left out.
/// - Awaiting confirmation: a manual renewal due by [today] and not yet
///   paid, on its next date.
/// - Expected: [futureCharges] after [today], unless that day is paid.
Map<int, List<CalendarCharge>> chargesInMonth(
  int year,
  int month, {
  required Iterable<Payment> payments,
  required Iterable<Subscription> subs,
  required DateTime today,
}) {
  final live = {
    for (final sub in subs)
      if (!sub.deleted) sub.id: sub,
  };
  final first = utcDate(year, month, 1);
  final next = DateTime.utc(year, month + 1);
  bool inMonth(DateTime date) => !date.isBefore(first) && date.isBefore(next);
  final paidDays = <(String, DateTime)>{};
  final entries = <(DateTime, Subscription, CalendarCharge)>[];
  void add(
    DateTime date,
    Subscription sub,
    int minor,
    String currency,
    ChargeKind kind,
  ) {
    entries.add((
      date,
      sub,
      CalendarCharge(
        subscriptionId: sub.id,
        amountMinor: minor,
        currency: currency,
        kind: kind,
      ),
    ));
  }

  for (final p in payments) {
    final sub = live[p.subscriptionId];
    if (p.deleted || sub == null || !inMonth(p.paidOn)) continue;
    paidDays.add((sub.id, p.paidOn));
    add(p.paidOn, sub, p.amountMinor, p.currency, ChargeKind.paid);
  }
  for (final sub in live.values) {
    final due = sub.nextDate;
    if (due == null ||
        !sub.isAwaitingConfirmation(today) ||
        !inMonth(due) ||
        paidDays.contains((sub.id, due))) {
      continue;
    }
    if (amountFor(sub, due) case final minor?) {
      add(due, sub, minor, sub.currency, ChargeKind.awaitingConfirmation);
    }
  }
  for (final c in futureCharges(
    live.values,
    today: today,
    untilExclusive: next,
    from: first,
  )) {
    if (!paidDays.contains((c.sub.id, c.date))) {
      add(c.date, c.sub, c.amountMinor, c.sub.currency, ChargeKind.expected);
    }
  }

  entries.sort(
    (a, b) => switch (a.$3.kind.index.compareTo(b.$3.kind.index)) {
      0 => compareNames(a.$2.name, b.$2.name),
      final order => order,
    },
  );
  final byDay = <int, List<CalendarCharge>>{};
  for (final (date, _, charge) in entries) {
    (byDay[date.day] ??= []).add(charge);
  }
  return byDay;
}
