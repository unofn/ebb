import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/reminders/platform/notification_port.dart';
import '../../features/reminders/platform/plugin_notifications.dart';
import '../../features/reminders/platform/reminder_responses.dart';
import '../../features/reminders/platform/reminder_scheduler.dart';
import '../../features/reminders/platform/timer_notifications.dart';
import '../l10n/system_l10n.dart';
import 'rate_providers.dart';
import 'repository_providers.dart';

part 'reminder_providers.g.dart';

/// Initialized by `initNotifications` in `main` before the first frame.
@Riverpod(keepAlive: true)
FlutterLocalNotificationsPlugin notificationsPlugin(Ref ref) =>
    FlutterLocalNotificationsPlugin();

/// The plugin, or on Linux (no scheduling there) timers that show through
/// it while the app runs.
@Riverpod(keepAlive: true)
NotificationPort notificationPort(Ref ref) {
  final plugin = PluginNotifications(
    ref.watch(notificationsPluginProvider),
    texts: systemL10n,
  );
  if (!Platform.isLinux) return plugin;
  final timers = TimerNotifications(show: plugin.show);
  ref.onDispose(timers.dispose);
  return timers;
}

@Riverpod(keepAlive: true)
ReminderScheduler reminderScheduler(Ref ref) =>
    ReminderScheduler(ref.watch(notificationPortProvider), texts: systemL10n);

/// Taps on reminders; the router listens to `openRequests`.
@Riverpod(keepAlive: true)
ReminderResponses reminderResponses(Ref ref) {
  final responses = ReminderResponses(
    subscriptions: ref.watch(subscriptionRepositoryProvider),
    payments: ref.watch(paymentRepositoryProvider),
    rates: ref.watch(rateRepositoryProvider),
    settings: ref.watch(localSettingsProvider),
  );
  ref.onDispose(responses.dispose);
  return responses;
}
