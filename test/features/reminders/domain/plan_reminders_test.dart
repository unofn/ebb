import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/features/reminders/domain/plan_reminders.dart';
import 'package:ebb/features/reminders/domain/planned_reminder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  // 本机时间 2026-10-11 10:00。
  final now = DateTime(2026, 10, 11, 10);
  List<PlannedReminder> plan(
    Iterable<Subscription> subs, {
    ReminderDefaults defaults = const ReminderDefaults(),
  }) => withClock(
    Clock.fixed(now),
    () => planReminders(subs, defaults: defaults),
  );
  Subscription due(DateTime next, {String id = 'sub-1'}) =>
      fakeSubscription(id: id, nextDate: next).copyWith(reminderEnabled: true);

  test('renewal with the defaults: 3 days before at 09:00 local', () {
    final reminder = plan([due(utcDate(2026, 10, 20))]).single;
    expect(reminder.kind, ReminderKind.renewal);
    expect(reminder.fireAt, DateTime(2026, 10, 17, 9));
    expect(reminder.fireAt.isUtc, isFalse);
    expect(reminder.daysBefore, 3);
    expect(reminder.eventDate, utcDate(2026, 10, 20));
    expect(reminder.amountMinor, 1200);
    expect(reminder.currency, 'CNY');
    expect(reminder.name, 'Video');
    expect(reminder.canMarkPaid, isFalse);
  });

  test('device defaults and per-subscription settings', () {
    final sub = due(utcDate(2026, 10, 20));
    const defaults = ReminderDefaults(daysBefore: 5, minuteOfDay: 8 * 60);
    expect(
      plan([sub], defaults: defaults).single.fireAt,
      DateTime(2026, 10, 15, 8),
    );
    final own = sub.copyWith(
      reminderDays: const Value(1),
      reminderTime: const Value(20 * 60 + 30),
    );
    expect(
      plan([own], defaults: defaults).single.fireAt,
      DateTime(2026, 10, 19, 20, 30),
    );
  });

  test('a manual renewal offers the paid action', () {
    final manual = due(utcDate(2026, 10, 20)).copyWith(autoRenew: false);
    expect(plan([manual]).single.canMarkPaid, isTrue);
  });

  test('past times are skipped, including earlier today', () {
    expect(plan([due(utcDate(2026, 10, 13))]), isEmpty);
    expect(plan([due(utcDate(2026, 10, 14))]), isEmpty); // 今天 09:00 已过
    expect(
      plan([due(utcDate(2026, 10, 15))]).single.fireAt,
      DateTime(2026, 10, 12, 9),
    );
  });

  test('only within the 60-day horizon', () {
    // 12-07 − 3 天 = 12-04 09:00，在 now + 60 天（12-10 10:00）之内
    expect(plan([due(utcDate(2026, 12, 7))]), hasLength(1));
    expect(plan([due(utcDate(2026, 12, 14))]), isEmpty);
  });

  test('earliest first, capped at 48', () {
    final subs = [
      for (var i = 59; i >= 0; i--)
        due(utcDate(2026, 10, 15).add(Duration(days: i)), id: 'sub-$i'),
    ];
    final planned = plan(subs);
    expect(planned, hasLength(48));
    expect(planned.first.subscriptionId, 'sub-0');
    expect(planned.last.subscriptionId, 'sub-47');
    for (var i = 1; i < planned.length; i++) {
      expect(planned[i].fireAt.isBefore(planned[i - 1].fireAt), isFalse);
    }
  });

  test('disabled and deleted subscriptions get none', () {
    final sub = due(utcDate(2026, 10, 20));
    expect(plan([sub.copyWith(reminderEnabled: false)]), isEmpty);
    expect(plan([sub.copyWith(deleted: true)]), isEmpty);
  });
}
