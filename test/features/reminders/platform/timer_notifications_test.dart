import 'package:clock/clock.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/features/reminders/domain/planned_reminder.dart';
import 'package:ebb/features/reminders/platform/reminder_message.dart';
import 'package:ebb/features/reminders/platform/reminder_payload.dart';
import 'package:ebb/features/reminders/platform/timer_notifications.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final message = ReminderMessage(
    title: 'Netflix 即将扣费',
    body: '3 天后扣费 ¥15.00',
    payload: ReminderPayload(
      subscriptionId: 'sub-1',
      kind: ReminderKind.renewal,
      eventDate: utcDate(2026, 10, 20),
    ),
    buttons: const [],
  );

  void run(
    void Function(FakeAsync async, TimerNotifications timers) body,
    List<int> shown,
  ) {
    fakeAsync((async) {
      final timers = TimerNotifications(
        show: (id, message) async => shown.add(id),
      );
      body(async, timers);
      timers.dispose();
    }, initialTime: DateTime(2026, 10, 11, 10));
  }

  test('shows each reminder at its time, then forgets it', () {
    final shown = <int>[];
    run((async, timers) {
      final start = clock.now();
      timers
        ..schedule(1, start.add(const Duration(hours: 2)), message)
        ..schedule(2, start.add(const Duration(days: 3)), message);
      async.flushMicrotasks();

      async.elapse(const Duration(hours: 2));
      expect(shown, [1]);
      timers.pendingIds().then((ids) => expect(ids, {2}));

      async.elapse(const Duration(days: 3));
      expect(shown, [1, 2]);
    }, shown);
  });

  test('cancel and rescheduling the same ID replace the timer', () {
    final shown = <int>[];
    run((async, timers) {
      final start = clock.now();
      timers
        ..schedule(1, start.add(const Duration(hours: 1)), message)
        ..schedule(1, start.add(const Duration(hours: 5)), message)
        ..schedule(2, start.add(const Duration(hours: 1)), message)
        ..cancel(2);
      async.elapse(const Duration(hours: 4));
      expect(shown, isEmpty);
      async.elapse(const Duration(hours: 1));
      expect(shown, [1]);
    }, shown);
  });
}
