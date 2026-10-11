import 'package:money2/money2.dart';

import '../../../core/local_date.dart';
import '../../../core/money.dart';
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
                  oldValue: paymentMethodNames[old] ?? old as String?,
                  newValue: method?.name,
                )
              : FieldChange(
                  field,
                  oldValue: _show(field, old),
                  newValue: _show(field, now),
                ),
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
    (row.priceMinor, row.currency),
    (body.priceMinor, body.currency),
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
    (row.reminderEnabled, row.reminderDays),
    (body.reminderEnabled, body.reminderDays),
  ),
  ImportField.reminderTime => (row.reminderTime, body.reminderTime),
};

String? _show(ImportField field, Object? value) => switch ((field, value)) {
  (_, null) => null,
  (ImportField.color, final int rgb) =>
    '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}',
  (ImportField.reminderTime, final int minutes) =>
    '${_twoDigits(minutes ~/ 60)}:${_twoDigits(minutes % 60)}',
  (_, final DateTime date) => date.isoDate,
  (_, Cycle(:final unit, :final count)) => '$count ${unit.name}',
  (_, (final int minor, final String code)) =>
    '${Money.fromIntWithCurrency(minor, currencyOf(code)).amount} $code',
  (_, (final bool on, final int? days)) => on ? 'on, ${days ?? '?'}d' : 'off',
  (_, final Enum value) => value.name,
  (_, final value) => '$value',
};

String _twoDigits(int n) => '$n'.padLeft(2, '0');
