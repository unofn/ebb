import 'package:freezed_annotation/freezed_annotation.dart';

part 'planned_reminder.freezed.dart';

enum ReminderKind {
  /// The next charge.
  renewal,

  /// An ending subscription's last day.
  ending,

  /// A trial converting to a paid subscription.
  trial,

  /// An intro offer ending; the regular price follows.
  intro,
}

/// Device-wide defaults for subscriptions without their own settings.
@freezed
abstract class ReminderDefaults with _$ReminderDefaults {
  const factory ReminderDefaults({
    @Default(3) int daysBefore,

    /// Minutes after midnight (540 = 09:00).
    @Default(540) int minuteOfDay,
  }) = _ReminderDefaults;
}

/// A notification to schedule. The platform layer turns [fireAt]'s
/// wall-clock fields into a `TZDateTime` in the local zone and localizes
/// the text from [kind] and the fields below.
@freezed
abstract class PlannedReminder with _$PlannedReminder {
  const factory PlannedReminder({
    /// Stable 31-bit notification ID.
    required int id,
    required String subscriptionId,
    required ReminderKind kind,

    /// Local wall-clock time (a local `DateTime`).
    required DateTime fireAt,
    required String name,

    /// The date-only day the reminder is about (charge, end, trial end).
    required DateTime eventDate,
    required int daysBefore,

    /// Renewal: the charge; intro: the price after the offer. Null for
    /// ending and trial without a price.
    int? amountMinor,
    required String currency,

    /// A manual renewal: offer the 「已付款」 action.
    @Default(false) bool canMarkPaid,
  }) = _PlannedReminder;
}
