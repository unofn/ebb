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

/// One field a re-import would change; values are display strings (null =
/// empty), not localized.
@freezed
abstract class FieldChange with _$FieldChange {
  const factory FieldChange(
    ImportField field, {
    String? oldValue,
    String? newValue,
  }) = _FieldChange;
}
