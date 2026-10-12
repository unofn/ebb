import '../../../../app/format/date_text.dart';
import '../../../../app/format/money_text.dart';
import '../../../../app/l10n/cycle_names.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/l10n/status_names.dart';
import '../../../../data/enums.dart';
import '../../../billing/cycle.dart';
import '../../plan/field_change.dart';

/// 「价格 ¥13.99 → ¥15.49」; an empty side shows as 「—」.
String changeText(AppLocalizations l10n, FieldChange change) =>
    '${fieldLabel(l10n, change.field)} ${changeValues(l10n, change)}';

String changeValues(AppLocalizations l10n, FieldChange change) =>
    '${fieldValueText(l10n, change.field, change.oldValue)} → '
    '${fieldValueText(l10n, change.field, change.newValue)}';

/// A [FieldChange] value of [field] as people read it, in the l10n's
/// language.
String fieldValueText(
  AppLocalizations l10n,
  ImportField field,
  Object? value,
) => switch (value) {
  null => '—',
  final String text => text,
  final DateTime date => fullDayText(l10n.localeName, date),
  final Cycle cycle => cycleName(l10n, cycle),
  (minor: final int minor, currency: final String code) => moneyText(
    minor,
    code,
  ),
  (enabled: final bool on, days: final int? days) =>
    !on
        ? l10n.detailReminderOff
        : days == null
        ? l10n.changeOn
        : l10n.reminderBefore(days),
  final SubscriptionStatus status => statusName(l10n, status),
  SubscriptionKind.oneTime => l10n.oneTime,
  SubscriptionKind.recurring => l10n.changeRecurring,
  final bool yes => yes ? l10n.changeYes : l10n.changeNo,
  final int minutes when field == ImportField.reminderTime =>
    '${_twoDigits(minutes ~/ 60)}:${_twoDigits(minutes % 60)}',
  final int rgb => '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}',
  final other => '$other',
};

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

String _twoDigits(int n) => '$n'.padLeft(2, '0');
