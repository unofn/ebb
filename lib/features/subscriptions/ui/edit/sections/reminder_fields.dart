import 'package:flutter/material.dart';

import '../../../../../app/l10n/l10n.dart';
import '../../../../reminders/domain/planned_reminder.dart';
import '../fields/form_text_field.dart';
import '../fields/labeled_field.dart';
import '../fields/time_field.dart';
import '../form/error_text.dart';
import '../form/form_binding.dart';
import '../form/form_errors.dart';

/// 「默认提前 3 天 · 09:00」.
String reminderHint(AppLocalizations l10n, ReminderDefaults defaults) =>
    l10n.editReminderHint(defaults.daysBefore, clockText(defaults.minuteOfDay));

/// Days before and time; blank or untouched values follow the defaults.
List<Widget> reminderFields(
  BuildContext context,
  FormBinding binding,
  ReminderDefaults defaults,
) {
  final l10n = context.l10n;
  final error = binding.errorOf([FormError.reminderDaysInvalid]);
  return [
    LabeledField(
      label: l10n.editReminderDays,
      error: errorText(l10n, error),
      child: FormTextField(
        value: binding.form.reminderDays,
        hint: '${defaults.daysBefore}',
        number: true,
        error: error != null,
        onChanged: (text) =>
            binding.update((f) => f.copyWith(reminderDays: text)),
      ),
    ),
    LabeledField(
      label: l10n.editReminderTime,
      child: TimeField(
        value: binding.form.reminderTime,
        fallback: defaults.minuteOfDay,
        onChanged: (minutes) =>
            binding.update((f) => f.copyWith(reminderTime: minutes)),
      ),
    ),
  ];
}
