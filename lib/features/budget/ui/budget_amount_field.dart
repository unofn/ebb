import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../core/money.dart';

/// The big amount input, the base currency's symbol in front.
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
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: big.copyWith(color: c.ink),
      decoration: InputDecoration(
        labelText: l10n.budgetSheetLimit(currency.toUpperCase()),
        hintText: l10n.budgetSheetNoLimit,
        hintStyle: big.copyWith(color: c.ink3),
        errorText: error,
        prefixText: '$symbol ',
        prefixStyle: big.copyWith(color: c.ink2),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
