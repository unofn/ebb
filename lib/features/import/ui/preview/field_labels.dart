import '../../../../app/l10n/l10n.dart';
import '../../plan/field_change.dart';

/// 「价格 $13.99 → $15.49」. Values come from the plan as plain display
/// strings; an empty side shows as 「—」.
String changeText(AppLocalizations l10n, FieldChange change) =>
    '${fieldLabel(l10n, change.field)} ${changeValues(change)}';

String changeValues(FieldChange change) =>
    '${change.oldValue ?? '—'} → ${change.newValue ?? '—'}';

String fieldLabel(AppLocalizations l10n, ImportField field) => switch (field) {
  ImportField.name => l10n.fieldName,
  ImportField.description => l10n.fieldDescription,
  ImportField.kind => l10n.fieldKind,
  ImportField.price => l10n.fieldPrice,
  ImportField.cycle => l10n.fieldCycle,
  ImportField.startDate => l10n.fieldStartDate,
  ImportField.nextDate => l10n.fieldNextDate,
  ImportField.endDate => l10n.fieldEndDate,
  ImportField.endDateUnknown => l10n.fieldEndDateUnknown,
  ImportField.status => l10n.fieldStatus,
  ImportField.autoRenew => l10n.fieldAutoRenew,
  ImportField.paymentMethod => l10n.fieldPaymentMethod,
  ImportField.color => l10n.fieldColor,
  ImportField.url => l10n.fieldUrl,
  ImportField.notes => l10n.fieldNotes,
  ImportField.reminder => l10n.fieldReminder,
  ImportField.reminderTime => l10n.fieldReminderTime,
};
