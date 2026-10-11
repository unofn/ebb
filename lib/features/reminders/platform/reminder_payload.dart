import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/local_date.dart';
import '../domain/planned_reminder.dart';

part 'reminder_payload.freezed.dart';

/// Action IDs of reminder notifications; both open the app (foreground).
abstract final class ReminderActions {
  /// Confirms a manual renewal's charge (`markPaid`).
  static const markPaid = 'mark_paid';

  /// Opens the subscription, like tapping the notification.
  static const manage = 'manage';
}

/// What a reminder notification hands back when the user responds: the
/// subscription, the reminder and the day it is about. [action] is set
/// only where a button can carry no action ID of its own (Windows passes
/// its arguments back as both action and payload).
@freezed
abstract class ReminderPayload with _$ReminderPayload {
  const factory ReminderPayload({
    required String subscriptionId,
    required ReminderKind kind,

    /// Date-only (UTC 00:00).
    required DateTime eventDate,
    String? action,
  }) = _ReminderPayload;

  const ReminderPayload._();

  factory ReminderPayload.of(PlannedReminder reminder) => ReminderPayload(
    subscriptionId: reminder.subscriptionId,
    kind: reminder.kind,
    eventDate: reminder.eventDate,
  );

  /// The payload, or null when [text] is not one (another app version,
  /// an empty payload).
  static ReminderPayload? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, dynamic>) return null;
      final kind = ReminderKind.values.asNameMap()[json['k']];
      final id = json['s'], date = json['d'], action = json['a'];
      if (kind == null || id is! String || date is! String) return null;
      if (action != null && action is! String) return null;
      return ReminderPayload(
        subscriptionId: id,
        kind: kind,
        eventDate: parseIsoDate(date),
        action: action as String?,
      );
    } on FormatException {
      return null;
    }
  }

  String encode() => jsonEncode({
    's': subscriptionId,
    'k': kind.name,
    'd': eventDate.isoDate,
    'a': ?action,
  });
}
