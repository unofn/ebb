import 'dart:developer';

import 'package:clock/clock.dart';

import '../../../app/l10n/app_localizations.dart';
import '../domain/planned_reminder.dart';
import 'notification_port.dart';
import 'reminder_message.dart';

/// Keeps the system's pending reminders equal to the latest plan.
class ReminderScheduler {
  /// [texts] gives the strings for the current system language.
  ReminderScheduler(this._port, {required this._texts});

  final NotificationPort _port;
  final AppLocalizations Function() _texts;

  // 每次运行只主动问一次：系统弹窗会让 App 失焦再回前台，又触发重排。
  bool _askedPermission = false;

  /// Cancels pending reminders that are no longer [planned] and schedules
  /// the rest again (same ID replaces). With something to remind of and
  /// no permission yet, asks for it, once per app run.
  Future<void> reschedule(List<PlannedReminder> planned) async {
    final wanted = {for (final reminder in planned) reminder.id};
    for (final id in await _port.pendingIds()) {
      if (!wanted.contains(id)) await _port.cancel(id);
    }
    if (planned.isEmpty) return;
    if (!_askedPermission && !await _port.permitted()) {
      _askedPermission = true;
      await _port.requestPermission();
    }
    final l10n = _texts();
    for (final reminder in planned) {
      // 计划和排期之间时间在走；过去的时刻有的平台直接抛错。
      if (!reminder.fireAt.isAfter(clock.now())) continue;
      try {
        await _port.schedule(
          reminder.id,
          reminder.fireAt,
          ReminderMessage.of(reminder, l10n),
        );
      } catch (e, stack) {
        log(
          'schedule ${reminder.id} failed',
          name: 'ebb.reminders',
          error: e,
          stackTrace: stack,
        );
      }
    }
  }

  /// For the settings page.
  Future<bool> permitted() => _port.permitted();

  Future<bool> requestPermission() => _port.requestPermission();
}
