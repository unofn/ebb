import 'package:intl/intl.dart';

import '../draft/import_warning.dart';
import 'sm_cycle.dart';
import 'sm_fields.dart';
import 'sm_json.dart';

typedef SmReminder = ({bool enabled, int? days, int? time});

/// `Calendar.DAY_OF_YEAR`: the only rhythm seen in notifications, N days
/// before the due date.
const _daysBefore = 6;

final _time = DateFormat('HH:mm', 'en_US');

/// The reminder from [notification] (null = none). Days and time are kept
/// even when it is switched off, so turning it back on restores them.
SmReminder smReminder(SmNotification? notification, SmWarn warn) {
  if (notification == null) return (enabled: false, days: null, time: null);
  final cycle = notification.cycle;
  int? days;
  if (cycle?.cycleRhythm == _daysBefore && cycle!.cycleDuration >= 0) {
    days = cycle.cycleDuration;
  } else {
    warn(ImportWarningCode.unknownReminderRhythm, describeSmCycle(cycle));
  }
  return (
    enabled: notification.status == 1,
    days: days,
    time: _minutesOfDay(notification.time, warn),
  );
}

int? _minutesOfDay(String? text, SmWarn warn) {
  if (text == null || text.trim().isEmpty) return null;
  final parsed = _time.tryParseStrict(text.trim(), true);
  // 没有专门的时间警告码，借用 invalidDate。
  if (parsed == null) warn(ImportWarningCode.invalidDate, text);
  return parsed == null ? null : parsed.hour * 60 + parsed.minute;
}
