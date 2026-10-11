import 'package:ebb/features/import/draft/import_warning.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sm_fixture.dart';

Map<String, Object?> notification(
  int subscriptionId, {
  int status = 1,
  String? time = '09:30',
  int days = 3,
  int rhythm = 6,
}) => {
  'subscriptionId': subscriptionId,
  'status': status,
  'time': time,
  'cycle': {'cycleDuration': days, 'cycleRhythm': rhythm, 'cycleType': 3},
  'content': r'$t is $p due',
  'fullName': 2,
};

void main() {
  test('days before and time of day', () {
    final draft = draftOf(smRecord(1), notifications: [notification(1)]);
    expect(draft.reminderEnabled, isTrue);
    expect(draft.reminderDays, 3);
    expect(draft.reminderTime, 9 * 60 + 30);
    expect(draft.warnings, isEmpty);
  });

  test('matched by subscriptionId; none means off', () {
    final draft = draftOf(smRecord(1), notifications: [notification(2)]);
    expect(draft.reminderEnabled, isFalse);
    expect(draft.reminderDays, isNull);
    expect(draft.reminderTime, isNull);
  });

  test('switched off keeps its days and time', () {
    final draft = draftOf(
      smRecord(1),
      notifications: [notification(1, status: 0, time: '20:05', days: 1)],
    );
    expect(draft.reminderEnabled, isFalse);
    expect(draft.reminderDays, 1);
    expect(draft.reminderTime, 20 * 60 + 5);
  });

  test('the first of several notifications wins', () {
    final draft = draftOf(
      smRecord(1),
      notifications: [notification(1, days: 2), notification(1, days: 7)],
    );
    expect(draft.reminderDays, 2);
  });

  test('a rhythm other than days warns and leaves days empty', () {
    final draft = draftOf(
      smRecord(1),
      notifications: [notification(1, rhythm: 2)],
    );
    expect(draft.reminderEnabled, isTrue);
    expect(draft.reminderDays, isNull);
    expect(draft.warnings, [
      const ImportWarning(
        ImportWarningCode.unknownReminderRhythm,
        sourceId: '1',
        detail: 'rhythm 2 × 3',
      ),
    ]);
  });

  test('an unreadable time warns and is dropped', () {
    final draft = draftOf(
      smRecord(1),
      notifications: [notification(1, time: 'noon')],
    );
    expect(draft.reminderTime, isNull);
    expect(draft.reminderDays, 3);
    expect(codesOf(draft), [ImportWarningCode.invalidDate]);
  });
}
