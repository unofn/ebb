import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../app/l10n/app_localizations.dart';
import 'notification_details.dart';
import 'reminder_payload.dart';

/// Plugin settings for every platform. Darwin asks for permission only
/// when `requestPermission` is called, not at init; its button titles are
/// fixed here, in the language at launch.
InitializationSettings notificationSettings(AppLocalizations l10n) {
  const foreground = {DarwinNotificationActionOption.foreground};
  final markPaid = DarwinNotificationAction.plain(
    ReminderActions.markPaid,
    l10n.reminderMarkPaid,
    options: foreground,
  );
  final manage = DarwinNotificationAction.plain(
    ReminderActions.manage,
    l10n.reminderManage,
    options: foreground,
  );
  final darwin = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    notificationCategories: [
      DarwinNotificationCategory(
        ReminderCategories.markable,
        actions: [markPaid, manage],
      ),
      DarwinNotificationCategory(ReminderCategories.plain, actions: [manage]),
    ],
  );
  return InitializationSettings(
    android: const AndroidInitializationSettings(androidNotificationIcon),
    iOS: darwin,
    macOS: darwin,
    linux: LinuxInitializationSettings(defaultActionName: l10n.reminderManage),
    windows: const WindowsInitializationSettings(
      appName: 'Ebb',
      appUserModelId: 'Unofn.Ebb',
      // 固定值，定了不改：Windows 用它认出同一个 App。
      guid: '5d0f6a52-8a3e-4c1b-9b7e-2f4c6e1d8a93',
    ),
  );
}

/// The channel, created up front so system settings list it by name
/// before the first reminder; re-creating it updates the name.
AndroidNotificationChannel reminderChannel(AppLocalizations l10n) =>
    AndroidNotificationChannel(
      reminderChannelId,
      l10n.reminderChannelName,
      description: l10n.reminderChannelDescription,
      importance: Importance.high,
    );
