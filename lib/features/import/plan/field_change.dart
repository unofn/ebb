import 'package:freezed_annotation/freezed_annotation.dart';

part 'field_change.freezed.dart';

/// A subscription field an import can overwrite. Category, icon, tags and
/// payments are never overwritten, so they are not listed.
enum ImportField {
  name,
  description,
  kind,

  /// Amount and currency together.
  price,
  cycle,
  startDate,
  nextDate,
  endDate,
  endDateUnknown,
  status,
  autoRenew,
  paymentMethod,
  color,
  url,
  notes,

  /// Enabled and days before.
  reminder,
  reminderTime,
}

/// A price as stored: minor units of [currency].
typedef PriceValue = ({int minor, String currency});

/// The reminder switch and its days before (null = the default).
typedef ReminderValue = ({bool enabled, int? days});

/// One field a re-import would change, old and new value typed for the
/// interface to format (null = empty):
/// - name, description, url, notes, payment method (its name): `String`;
/// - kind: `SubscriptionKind`; status: `SubscriptionStatus`;
/// - price: [PriceValue]; cycle: `Cycle`; reminder: [ReminderValue];
/// - start, next and end dates: date-only `DateTime`;
/// - end date unknown, auto-renew: `bool`;
/// - color: `int` 0xRRGGBB; reminder time: `int` minutes after midnight.
@freezed
abstract class FieldChange with _$FieldChange {
  const factory FieldChange(
    ImportField field, {
    Object? oldValue,
    Object? newValue,
  }) = _FieldChange;
}
