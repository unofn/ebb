import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'reminder_message.dart';

/// The Android channel every reminder goes to.
const reminderChannelId = 'renewal_reminders';

/// Notification icon: `android/app/src/main/res/drawable/ic_notification.xml`.
const androidNotificationIcon = 'ic_notification';

/// Darwin categories (registered at init) carry the buttons there.
abstract final class ReminderCategories {
  /// 「已付款」 and 「管理订阅」.
  static const markable = 'reminder_markable';

  /// 「管理订阅」 only.
  static const plain = 'reminder_plain';
}

/// [message]'s look on every platform. [channelName] and
/// [channelDescription] name the Android channel in system settings.
NotificationDetails reminderDetails(
  ReminderMessage message, {
  required String channelName,
  required String channelDescription,
}) {
  final payload = message.payload;
  return NotificationDetails(
    android: AndroidNotificationDetails(
      reminderChannelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      styleInformation: BigTextStyleInformation(message.body),
      actions: [
        for (final button in message.buttons)
          AndroidNotificationAction(
            button.id,
            button.label,
            showsUserInterface: true,
          ),
      ],
    ),
    iOS: _darwin(message),
    macOS: _darwin(message),
    linux: LinuxNotificationDetails(
      actions: [
        for (final button in message.buttons)
          LinuxNotificationAction(key: button.id, label: button.label),
      ],
    ),
    windows: WindowsNotificationDetails(
      actions: [
        // Windows 把按钮的 arguments 同时当作 actionId 和 payload 交回。
        for (final button in message.buttons)
          WindowsAction(
            content: button.label,
            arguments: payload.copyWith(action: button.id).encode(),
          ),
      ],
    ),
  );
}

DarwinNotificationDetails _darwin(ReminderMessage message) =>
    DarwinNotificationDetails(
      categoryIdentifier: message.canMarkPaid
          ? ReminderCategories.markable
          : ReminderCategories.plain,
    );
