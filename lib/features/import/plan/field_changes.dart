import '../../../data/database.dart';
import '../../billing/cycle.dart';
import '../draft/import_draft.dart';
import 'field_change.dart';
import 'import_ids.dart';
import 'source_fields.dart';

/// The source fields where [body] differs from [row], an earlier import
/// of it. [paymentMethodNames] (ID → name) shows the old payment method.
List<FieldChange> fieldChanges(
  Subscription row,
  ImportDraft body, {
  Map<String, String> paymentMethodNames = const {},
}) {
  final method = body.paymentMethod;
  final methodId = method == null
      ? null
      : importedPaymentMethodId(body.sourceApp, method);
  final fields = sourceFieldsOf(body.sourceApp);
  return [
    for (final field in ImportField.values)
      if (fields.contains(field))
        if (_values(field, row, body, methodId) case (final old, final now)
            when old != now)
          field == ImportField.paymentMethod
              ? FieldChange(
                  field,
                  oldValue: paymentMethodNames[old] ?? old,
                  newValue: method?.name,
                )
              : FieldChange(field, oldValue: old, newValue: now),
  ];
}

(Object?, Object?) _values(
  ImportField field,
  Subscription row,
  ImportDraft body,
  String? methodId,
) => switch (field) {
  ImportField.name => (row.name, body.name),
  ImportField.description => (row.description, body.description),
  ImportField.kind => (row.kind, body.kind),
  ImportField.price => (
    (minor: row.priceMinor, currency: row.currency),
    (minor: body.priceMinor, currency: body.currency),
  ),
  ImportField.cycle => (row.cycle, body.cycle),
  ImportField.startDate => (row.startDate, body.startDate),
  ImportField.nextDate => (row.nextDate, body.nextDate),
  ImportField.endDate => (row.endDate, body.endDate),
  ImportField.endDateUnknown => (row.endDateUnknown, body.endDateUnknown),
  ImportField.status => (row.status, body.status),
  ImportField.autoRenew => (row.autoRenew, body.autoRenew),
  ImportField.paymentMethod => (row.paymentMethodId, methodId),
  ImportField.color => (row.color, body.color),
  ImportField.url => (row.url, body.url),
  ImportField.notes => (row.notes, body.notes),
  ImportField.reminder => (
    (enabled: row.reminderEnabled, days: row.reminderDays),
    (enabled: body.reminderEnabled, days: body.reminderDays),
  ),
  ImportField.reminderTime => (row.reminderTime, body.reminderTime),
};
