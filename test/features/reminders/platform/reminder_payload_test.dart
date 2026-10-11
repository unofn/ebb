import 'package:ebb/core/local_date.dart';
import 'package:ebb/features/reminders/domain/planned_reminder.dart';
import 'package:ebb/features/reminders/platform/reminder_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final payload = ReminderPayload(
    subscriptionId: 'sub-1',
    kind: ReminderKind.renewal,
    eventDate: utcDate(2026, 10, 20),
  );

  test('round-trips subscription, kind and day', () {
    final text = payload.encode();
    expect(text, '{"s":"sub-1","k":"renewal","d":"2026-10-20"}');
    expect(ReminderPayload.decode(text), payload);
  });

  test('carries an action for Windows buttons', () {
    final withAction = payload.copyWith(action: ReminderActions.markPaid);
    expect(ReminderPayload.decode(withAction.encode()), withAction);
  });

  test('anything else decodes to null', () {
    for (final text in [
      null,
      '',
      'mark_paid',
      '[]',
      '{"s":"sub-1","k":"weekly","d":"2026-10-20"}',
      '{"s":"sub-1","k":"renewal","d":"20 Oct"}',
      '{"s":1,"k":"renewal","d":"2026-10-20"}',
      '{"s":"sub-1","k":"renewal","d":"2026-10-20","a":3}',
    ]) {
      expect(ReminderPayload.decode(text), isNull, reason: text);
    }
  });
}
