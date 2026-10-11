import 'reminder_message.dart';

/// What reminders need from the system's notifications; the plugin, or
/// in-app timers on Linux, behind it. Tests use a fake.
abstract interface class NotificationPort {
  /// IDs scheduled and not shown yet.
  Future<Set<int>> pendingIds();

  /// Shows [message] at [fireAt], a local wall-clock time; replaces a
  /// pending notification with the same [id].
  Future<void> schedule(int id, DateTime fireAt, ReminderMessage message);

  Future<void> cancel(int id);

  /// Whether the user lets Ebb show notifications.
  Future<bool> permitted();

  /// Asks the user (Android 13+, iOS, macOS); returns [permitted]. The
  /// system shows its prompt only while the user has not decided.
  Future<bool> requestPermission();
}
