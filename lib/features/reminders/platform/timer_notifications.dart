import 'dart:async';
import 'dart:developer';

import 'package:clock/clock.dart';

import 'notification_port.dart';
import 'reminder_message.dart';

/// Shows a notification now.
typedef ShowNotification = Future<void> Function(int id, ReminderMessage m);

/// [NotificationPort] for Linux, where the plugin cannot schedule: a timer
/// per reminder while the app runs (in the tray when its window is
/// closed). Reminders due while the app is not running are not shown.
class TimerNotifications implements NotificationPort {
  TimerNotifications({required this._show});

  final ShowNotification _show;
  final _timers = <int, Timer>{};

  @override
  Future<Set<int>> pendingIds() async => _timers.keys.toSet();

  @override
  Future<void> schedule(
    int id,
    DateTime fireAt,
    ReminderMessage message,
  ) async {
    _timers.remove(id)?.cancel();
    _timers[id] = Timer(fireAt.difference(clock.now()), () {
      _timers.remove(id);
      // 有总线没通知服务时 DBus 调用会报错，记下即可。
      unawaited(_show(id, message).catchError(_logShowError));
    });
  }

  @override
  Future<void> cancel(int id) async => _timers.remove(id)?.cancel();

  /// Linux has no notification permission.
  @override
  Future<bool> permitted() async => true;

  @override
  Future<bool> requestPermission() async => true;

  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}

void _logShowError(Object e, StackTrace stack) => log(
  'notifications: show failed',
  name: 'ebb.reminders',
  error: e,
  stackTrace: stack,
);
