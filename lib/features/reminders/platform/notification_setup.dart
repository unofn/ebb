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
/// launched the app goes to [onResponse] like any later one. Failures are
/// logged; the app runs without reminders then.
Future<void> initNotifications(
  FlutterLocalNotificationsPlugin plugin, {
  required AppLocalizations l10n,
  required ReminderResponseHandler onResponse,
}) async {
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

  try {
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
  } catch (e, stack) {
    _logError('init')(e, stack);
  }
}

void Function(Object, StackTrace) _logError(String what) =>
    (e, stack) => log(
      'notifications: $what failed',
      name: 'ebb.reminders',
      error: e,
      stackTrace: stack,
    );
