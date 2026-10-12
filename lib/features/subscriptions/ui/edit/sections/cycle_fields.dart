import 'package:flutter/material.dart';

import '../../../../../app/l10n/l10n.dart';
import '../fields/date_field.dart';
import '../fields/form_text_field.dart';
import '../fields/labeled_field.dart';
import '../form/error_text.dart';
import '../form/form_binding.dart';
import '../form/form_errors.dart';
import 'unit_dropdown.dart';

/// 「每 [1] [月]」 and the first charge.
class CycleFields extends StatelessWidget {
  const CycleFields({super.key, required this.binding});

  final FormBinding binding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final form = binding.form;
    final countError = binding.errorOf([FormError.cycleCountInvalid]);
    final startError = binding.errorOf([FormError.startDateMissing]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Expanded(
          child: LabeledField(
            label: l10n.editEvery,
            error: errorText(l10n, countError),
            child: Row(
              spacing: 6,
              children: [
                SizedBox(
                  width: 56,
                  child: FormTextField(
                    value: form.cycleCount,
                    number: true,
                    error: countError != null,
                    onChanged: (count) =>
                        binding.update((f) => f.copyWith(cycleCount: count)),
                  ),
                ),
                Expanded(child: UnitDropdown(binding: binding)),
              ],
            ),
          ),
        ),
        Expanded(
          child: LabeledField(
            label: l10n.editFirstCharge,
            error: errorText(l10n, startError),
            child: DateField(
              value: form.startDate,
              error: startError != null,
              onChanged: (date) =>
                  binding.update((f) => f.copyWith(startDate: date)),
            ),
          ),
        ),
      ],
    );
  }
}
