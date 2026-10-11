import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../app/l10n/app_localizations.dart';
import 'notification_details.dart';
import 'notification_port.dart';
import 'reminder_message.dart';

/// [NotificationPort] over flutter_local_notifications (Android, iOS,
/// macOS, Windows). Initialize the plugin and `tz.local` first.
class PluginNotifications implements NotificationPort {
  PluginNotifications(this._plugin, {required this._texts});

  final FlutterLocalNotificationsPlugin _plugin;
  final AppLocalizations Function() _texts;

  @override
  Future<Set<int>> pendingIds() async => {
    for (final request in await _plugin.pendingNotificationRequests())
      request.id,
  };

  /// Android fires inexactly (no exact-alarm permission): within minutes
  /// of [fireAt], later in Doze.
  @override
  Future<void> schedule(int id, DateTime fireAt, ReminderMessage message) =>
      _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime(
          tz.local,
          fireAt.year,
          fireAt.month,
          fireAt.day,
          fireAt.hour,
          fireAt.minute,
        ),
        notificationDetails: _details(message),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: message.title,
        body: message.body,
        payload: message.payload.encode(),
      );

  /// Shows [message] now (Linux timers).
  Future<void> show(int id, ReminderMessage message) => _plugin.show(
    id: id,
    title: message.title,
    body: message.body,
    notificationDetails: _details(message),
    payload: message.payload.encode(),
  );

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<bool> permitted() async {
    if (_android case final android?) {
      return await android.areNotificationsEnabled() ?? false;
    }
    if (_ios case final ios?) {
      return (await ios.checkPermissions())?.isEnabled ?? false;
    }
    if (_macos case final macos?) {
      return (await macos.checkPermissions())?.isEnabled ?? false;
    }
    return true;
  }

  @override
  Future<bool> requestPermission() async {
    await _android?.requestNotificationsPermission();
    await _ios?.requestPermissions(alert: true, badge: true, sound: true);
    await _macos?.requestPermissions(alert: true, badge: true, sound: true);
    return permitted();
  }

  NotificationDetails _details(ReminderMessage message) {
    final l10n = _texts();
    return reminderDetails(
      message,
      channelName: l10n.reminderChannelName,
      channelDescription: l10n.reminderChannelDescription,
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  MacOSFlutterLocalNotificationsPlugin? get _macos => _plugin
      .resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin
      >();
}
