import 'package:clock/clock.dart';
import 'package:ebb/app/l10n/app_localizations.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/features/reminders/domain/planned_reminder.dart';
import 'package:ebb/features/reminders/platform/reminder_scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_port.dart';

void main() {
  // 本机时间 2026-10-11 10:00。
  final now = DateTime(2026, 10, 11, 10);
  PlannedReminder planned(int id, DateTime fireAt) => PlannedReminder(
    id: id,
    subscriptionId: 'sub-$id',
    kind: ReminderKind.renewal,
    fireAt: fireAt,
    name: 'Sub $id',
    eventDate: utcDate(2026, 10, 20),
    daysBefore: 3,
    amountMinor: 1500,
    currency: 'CNY',
  );
  ReminderScheduler scheduler(FakeNotificationPort port) => ReminderScheduler(
    port,
    texts: () => lookupAppLocalizations(const Locale('zh')),
  );
  Future<void> reschedule(
    FakeNotificationPort port,
    List<PlannedReminder> plan, {
    ReminderScheduler? on,
  }) => withClock(
    Clock.fixed(now),
    () => (on ?? scheduler(port)).reschedule(plan),
  );

  test('cancels stale pending reminders and schedules the plan', () async {
    final port = FakeNotificationPort(pending: {1, 2}, allowed: true);
    await reschedule(port, [
      planned(2, DateTime(2026, 10, 17, 9)),
      planned(3, DateTime(2026, 10, 18, 9)),
    ]);
    expect(port.cancelled, [1]);
    expect(port.pending.keys, unorderedEquals([2, 3]));
    final three = port.pending[3]!;
    expect(three.fireAt, DateTime(2026, 10, 18, 9));
    expect(three.message.title, 'Sub 3 即将扣费');
    expect(three.message.payload.subscriptionId, 'sub-3');
  });

  test('an empty plan cancels everything and asks nothing', () async {
    final port = FakeNotificationPort(pending: {1});
    await reschedule(port, []);
    expect(port.pending, isEmpty);
    expect(port.permissionRequests, 0);
  });

  test('asks for permission when something is planned, once', () async {
    final port = FakeNotificationPort();
    final once = scheduler(port);
    final plan = [planned(1, DateTime(2026, 10, 17, 9))];
    await reschedule(port, plan, on: once);
    await reschedule(port, plan, on: once);
    expect(port.permissionRequests, 1);

    final allowed = FakeNotificationPort(allowed: true);
    await reschedule(allowed, [planned(1, DateTime(2026, 10, 17, 9))]);
    expect(allowed.permissionRequests, 0);
  });

  test(
    'skips times already past; one failure does not stop the rest',
    () async {
      final port = FakeNotificationPort(allowed: true)..failing = {2};
      await reschedule(port, [
        planned(1, now),
        planned(2, DateTime(2026, 10, 17, 9)),
        planned(3, DateTime(2026, 10, 18, 9)),
      ]);
      expect(port.pending.keys, [3]);
    },
  );
}
