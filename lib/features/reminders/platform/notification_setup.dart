import 'dart:async';
import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../app/l10n/app_localizations.dart';
import 'local_timezone.dart';
import 'notification_settings.dart';

/// Handles a tap on a notification or one of its buttons.
typedef ReminderResponseHandler = Future<void> Function({
  String? actionId,
  String? payload,
});

/// Readies notifications before the first frame: the local time zone,
/// the plugin with its Darwin categories, the Android channel. A tap that
/// launched the app goes to [onResponse] like any later one. Failures,
/// including ones the plugin leaves behind after init (Linux without a
/// session bus), go to [onError], by default the log; the app runs
/// without reminders then.
Future<void> initNotifications(
  FlutterLocalNotificationsPlugin plugin, {
  required AppLocalizations l10n,
  required ReminderResponseHandler onResponse,
  void Function(Object, StackTrace)? onError,
}) {
  final failed = onError ?? _logError('init');
  final done = Completer<void>();
  // Linux 插件订阅信号时 package:dbus 在没人等的 future 里连会话总线，连不上
  // 的 SocketException 绕过 try/catch，只能靠出错区兜住；done 建在区外才传得出去。
  runZonedGuarded(() async {
    try {
      await _init(plugin, l10n, onResponse);
    } catch (e, stack) {
      failed(e, stack);
    }
    done.complete();
  }, failed);
  return done.future;
}

Future<void> _init(
  FlutterLocalNotificationsPlugin plugin,
  AppLocalizations l10n,
  ReminderResponseHandler onResponse,
) async {
  void respond(NotificationResponse response) {
    if (response.notificationResponseType ==
        NotificationResponseType.notificationDismissed) {
      return;
    }
    unawaited(
      onResponse(
        actionId: response.actionId,
        payload: response.payload,
      ).catchError(_logError('response')),
    );
  }

  await initLocalTimezone();
  await plugin.initialize(
    settings: notificationSettings(l10n),
    onDidReceiveNotificationResponse: respond,
  );
  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(reminderChannel(l10n));
  final launch = await plugin.getNotificationAppLaunchDetails();
  if (launch case NotificationAppLaunchDetails(
    didNotificationLaunchApp: true,
    :final notificationResponse?,
  )) {
    respond(notificationResponse);
  }
}

void Function(Object, StackTrace) _logError(String what) =>
    (e, stack) => log(
      'notifications: $what failed',
      name: 'ebb.reminders',
      error: e,
      stackTrace: stack,
    );
