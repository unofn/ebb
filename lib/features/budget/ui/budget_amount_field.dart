import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../core/money.dart';

/// 「每月上限 · CNY」 over the big amount input, the base currency's
/// symbol in front.
class BudgetAmountField extends StatelessWidget {
  const BudgetAmountField({
    super.key,
    required this.controller,
    required this.currency,
    required this.onChanged,
    this.error,
  });

  final TextEditingController controller;
  final String currency;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final big = EbbType.large.tabular;
    final symbol = isKnownCurrency(currency)
        ? currencyOf(currency).symbol
        : currency.toUpperCase();
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );
    // 标签在框上方，和编辑页的 LabeledField 一样。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(
          l10n.budgetSheetLimit(currency.toUpperCase()),
          style: EbbType.small.copyWith(color: c.ink2),
        ),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          style: big.copyWith(color: c.ink),
          decoration: InputDecoration(
            hintText: l10n.budgetSheetNoLimit,
            hintStyle: big.copyWith(color: c.ink3),
            errorText: error,
            prefixText: '$symbol ',
            prefixStyle: big.copyWith(color: c.ink2),
            filled: true,
            fillColor: c.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            enabledBorder: border(c.lineStrong),
            focusedBorder: border(c.accent),
            errorBorder: border(c.danger),
            focusedErrorBorder: border(c.danger),
          ),
        ),
      ],
    );
  }
}
