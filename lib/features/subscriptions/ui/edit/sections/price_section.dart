import 'package:flutter/material.dart';

import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/widgets/segmented_tabs.dart';
import '../../../../../data/enums.dart';
import '../fields/date_field.dart';
import '../fields/form_text_field.dart';
import '../fields/labeled_field.dart';
import '../fields/tap_field.dart';
import '../form/error_text.dart';
import '../form/form_binding.dart';
import '../form/form_errors.dart';
import '../pickers/currency_sheet.dart';
import 'cycle_fields.dart';
import 'next_charge_line.dart';

/// Recurring or one-time, currency and price, then the cycle and first
/// charge (or the purchase date).
class PriceSection extends StatelessWidget {
  const PriceSection({super.key, required this.binding});

  final FormBinding binding;

  Future<void> _pickCurrency(BuildContext context) async {
    final code = await pickCurrency(context, binding.form.currency);
    if (code != null) binding.update((f) => f.copyWith(currency: code));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final form = binding.form;
    final priceError = binding.errorOf([FormError.priceInvalid]);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          SegmentedTabs(
            labels: [l10n.editKindRecurring, l10n.editKindOneTime],
            selected: form.kind.index,
            onSelected: (i) => binding.update(
              (f) => f.copyWith(kind: SubscriptionKind.values[i]),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              SizedBox(
                width: 96,
                child: LabeledField(
                  label: l10n.editCurrency,
                  child: TapField(
                    text: form.currency,
                    icon: Icons.expand_more,
                    onTap: () => _pickCurrency(context),
                  ),
                ),
              ),
              Expanded(
                child: LabeledField(
                  label: form.shared ? l10n.editTotalPrice : l10n.editPrice,
                  error: errorText(l10n, priceError),
                  child: FormTextField(
                    value: form.price,
                    number: true,
                    decimal: true,
                    error: priceError != null,
                    onChanged: (price) =>
                        binding.update((f) => f.copyWith(price: price)),
                  ),
                ),
              ),
            ],
          ),
          if (form.recurring) ...[
            CycleFields(binding: binding),
            NextChargeLine(binding: binding),
          ] else
            LabeledField(
              label: l10n.editPurchaseDate,
              error: errorText(
                l10n,
                binding.errorOf([FormError.startDateMissing]),
              ),
              child: DateField(
                value: form.startDate,
                error: binding.errors.contains(FormError.startDateMissing),
                onChanged: (date) =>
                    binding.update((f) => f.copyWith(startDate: date)),
              ),
            ),
        ],
      ),
    );
  }
}
