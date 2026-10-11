import 'package:ebb/features/reminders/platform/notification_port.dart';
import 'package:ebb/features/reminders/platform/reminder_message.dart';

/// Records what the scheduler asks of the system.
class FakeNotificationPort implements NotificationPort {
  FakeNotificationPort({Set<int> pending = const {}, this.allowed = false})
    : pending = {for (final id in pending) id: null};

  /// Pending IDs with what was scheduled under them (null: from before).
  final Map<int, ({DateTime fireAt, ReminderMessage message})?> pending;
  final cancelled = <int>[];
  bool allowed;
  int permissionRequests = 0;

  /// IDs whose scheduling throws.
  Set<int> failing = {};

  @override
  Future<Set<int>> pendingIds() async => pending.keys.toSet();

  @override
  Future<void> schedule(
    int id,
    DateTime fireAt,
    ReminderMessage message,
  ) async {
    if (failing.contains(id)) throw ArgumentError('cannot schedule $id');
    pending[id] = (fireAt: fireAt, message: message);
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    pending.remove(id);
  }

  @override
  Future<bool> permitted() async => allowed;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allowed;
  }
}
