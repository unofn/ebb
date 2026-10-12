import 'package:flutter/material.dart';

import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/widgets/surface_card.dart';
import '../../../../reminders/domain/planned_reminder.dart';
import '../form/form_binding.dart';
import 'offer_fields.dart';
import 'option_row.dart';
import 'reminder_fields.dart';

/// The switches under the price: renewal, trial and intro offer (recurring
/// only), sharing, reimbursement, reminders (recurring only).
class OptionsCard extends StatelessWidget {
  const OptionsCard({super.key, required this.binding, required this.defaults});

  final FormBinding binding;

  /// What a reminder without its own days and time follows.
  final ReminderDefaults defaults;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final form = binding.form;
    final recurring = form.recurring;
    return SurfaceCard(
      children: [
        if (recurring) ...[
          OptionRow(
            label: l10n.editAutoRenew,
            hint: l10n.editAutoRenewHint,
            value: form.autoRenew,
            onChanged: (on) => binding.update((f) => f.copyWith(autoRenew: on)),
          ),
          OptionRow(
            label: l10n.editTrial,
            hint: l10n.editTrialHint,
            value: form.trial,
            onChanged: (on) => binding.update((f) => f.copyWith(trial: on)),
            fields: trialFields(context, binding),
          ),
          OptionRow(
            label: l10n.editIntro,
            hint: l10n.editIntroHint,
            value: form.intro,
            onChanged: (on) => binding.update((f) => f.copyWith(intro: on)),
            fields: introFields(context, binding),
          ),
        ],
        OptionRow(
          label: l10n.editShared,
          hint: l10n.editSharedHint,
          value: form.shared,
          onChanged: (on) => binding.update((f) => f.copyWith(shared: on)),
          fields: shareFields(context, binding),
        ),
        OptionRow(
          label: l10n.editReimbursed,
          hint: l10n.editReimbursedHint,
          value: form.reimbursed,
          onChanged: (on) => binding.update((f) => f.copyWith(reimbursed: on)),
        ),
        if (recurring)
          OptionRow(
            label: l10n.editReminder,
            hint: reminderHint(l10n, defaults),
            value: form.reminder,
            onChanged: (on) => binding.update((f) => f.copyWith(reminder: on)),
            fields: reminderFields(context, binding, defaults),
          ),
      ],
    );
  }
}
