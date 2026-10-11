import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/reminders/domain/plan_reminders.dart';
import 'package:ebb/features/reminders/domain/planned_reminder.dart';
import 'package:ebb/features/reminders/domain/reminder_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  final now = DateTime(2026, 10, 11, 10);
  List<PlannedReminder> plan(Iterable<Subscription> subs) =>
      withClock(Clock.fixed(now), () => planReminders(subs));
  final sub = fakeSubscription(nextDate: utcDate(2026, 10, 25))
      .copyWith(reminderEnabled: true);

  test('a trial replaces the renewal on its last day', () {
    final trial = sub.copyWith(trialEndsOn: Value(utcDate(2026, 10, 25)));
    final reminder = plan([trial]).single;
    expect(reminder.kind, ReminderKind.trial);
    expect(reminder.amountMinor, 1200);
  });

  test('intro end tells the price that follows, renewal stays apart', () {
    final intro = sub.copyWith(
      introPriceMinor: const Value(100),
      introEndsOn: Value(utcDate(2026, 11, 1)),
    );
    final planned = plan([intro]);
    expect(planned.map((r) => r.kind), [
      ReminderKind.renewal,
      ReminderKind.intro,
    ]);
    expect(planned.first.amountMinor, 100);
    expect(planned.last.amountMinor, 1200);
  });

  test('an ending subscription is reminded of its end, not a renewal', () {
    final ending = sub.copyWith(
      status: SubscriptionStatus.ending,
      nextDate: const Value(null),
      endDate: Value(utcDate(2026, 10, 30)),
    );
    final reminder = plan([ending]).single;
    expect(reminder.kind, ReminderKind.ending);
    expect(reminder.fireAt, DateTime(2026, 10, 27, 9));
    expect(reminder.amountMinor, isNull);
  });

  test('paused, cancelled and one-time get none', () {
    for (final row in [
      sub.copyWith(status: SubscriptionStatus.paused),
      sub.copyWith(status: SubscriptionStatus.cancelled),
      sub.copyWith(kind: SubscriptionKind.oneTime),
    ]) {
      expect(plan([row]), isEmpty);
    }
  });

  group('ids', () {
    test('are stable across runs and input order', () {
      final other = sub.copyWith(
        id: 'sub-2',
        nextDate: Value(utcDate(2026, 10, 26)),
      );
      final first = plan([sub, other]).map((r) => r.id).toList();
      final second = plan([other, sub]).map((r) => r.id).toList();
      expect(second, first);
      expect(
        first.first,
        reminderId('sub-1', ReminderKind.renewal, utcDate(2026, 10, 25)),
      );
    });

    test('differ by kind and day, and fit in 31 bits', () {
      final day = utcDate(2026, 10, 25);
      final ids = {
        for (final kind in ReminderKind.values) reminderId('sub-1', kind, day),
        reminderId('sub-1', ReminderKind.renewal, utcDate(2026, 11, 25)),
        reminderId('sub-2', ReminderKind.renewal, day),
      };
      expect(ids, hasLength(6));
      expect(ids.every((id) => id >= 0 && id <= 0x7fffffff), isTrue);
    });
  });
}
