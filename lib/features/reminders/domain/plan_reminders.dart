import 'package:clock/clock.dart';

import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../subscriptions/domain/amount_due.dart';
import 'planned_reminder.dart';
import 'reminder_id.dart';

/// Reminders for [subs] due after [now] (default `clock.now()`) and within
/// [horizon], earliest first, at most [cap]. Each fires reminder_days
/// before its day at reminder_time (or [defaults]), local wall clock.
/// Only recurring, not deleted rows with reminders enabled:
/// - trial / intro: active with a trial / intro offer ending;
/// - ending: ending with an end date;
/// - renewal: active with a next date that is not already covered by the
///   trial or intro reminder of the same day.
List<PlannedReminder> planReminders(
  Iterable<Subscription> subs, {
  ReminderDefaults defaults = const ReminderDefaults(),
  DateTime? now,
  Duration horizon = const Duration(days: 60),
  int cap = 48,
}) {
  final from = now ?? clock.now();
  final until = from.add(horizon);
  final planned = [
    for (final sub in subs)
      for (final reminder in _remindersOf(sub, defaults))
        if (reminder.fireAt.isAfter(from) && !reminder.fireAt.isAfter(until))
          reminder,
  ];
  planned.sort(
    (a, b) => switch (a.fireAt.compareTo(b.fireAt)) {
      0 => a.id.compareTo(b.id),
      final order => order,
    },
  );
  return planned.take(cap).toList();
}

Iterable<PlannedReminder> _remindersOf(
  Subscription sub,
  ReminderDefaults defaults,
) sync* {
  if (sub.deleted ||
      !sub.reminderEnabled ||
      sub.kind != SubscriptionKind.recurring) {
    return;
  }
  final days = sub.reminderDays ?? defaults.daysBefore;
  final minute = sub.reminderTime ?? defaults.minuteOfDay;
  PlannedReminder remind(ReminderKind kind, DateTime day, {int? amount}) {
    final fireDay = day.subtract(Duration(days: days));
    return PlannedReminder(
      id: reminderId(sub.id, kind, day),
      subscriptionId: sub.id,
      kind: kind,
      fireAt: DateTime(
        fireDay.year,
        fireDay.month,
        fireDay.day,
        minute ~/ 60,
        minute % 60,
      ),
      name: sub.name,
      eventDate: day,
      daysBefore: days,
      amountMinor: amount,
      currency: sub.currency,
      canMarkPaid: kind == ReminderKind.renewal && !sub.autoRenew,
    );
  }

  final active = sub.status == SubscriptionStatus.active;
  final trialEnds = active ? sub.trialEndsOn : null;
  final introEnds = active && sub.introPriceMinor != null
      ? sub.introEndsOn
      : null;
  if (trialEnds != null) {
    yield remind(
      ReminderKind.trial,
      trialEnds,
      amount: amountFor(sub, trialEnds),
    );
  }
  if (introEnds != null) {
    yield remind(
      ReminderKind.intro,
      introEnds,
      amount: amountFor(sub, introEnds),
    );
  }
  if (sub.status == SubscriptionStatus.ending && sub.endDate != null) {
    yield remind(ReminderKind.ending, sub.endDate!);
  }
  final next = sub.nextDate;
  if (active && next != null && next != trialEnds && next != introEnds) {
    yield remind(ReminderKind.renewal, next, amount: amountFor(sub, next));
  }
}
