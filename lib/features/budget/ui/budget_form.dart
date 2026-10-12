import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../core/local_date.dart';
import '../domain/budget_presets.dart';
import 'budget_amount_field.dart';
import 'budget_amount_text.dart';
import 'budget_inputs.dart';
import 'budget_preview.dart';
import 'budget_sheet_title.dart';
import 'preset_chips.dart';

/// The sheet's content: amount, quick amounts, preview, save or clear.
class BudgetForm extends ConsumerStatefulWidget {
  const BudgetForm({super.key});

  @override
  ConsumerState<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<BudgetForm> {
  final _amount = TextEditingController();
  final _today = today();
  bool _filled = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save(int? minor) async {
    await ref.read(localSettingsProvider).setBudgetMonthlyMinor(minor);
    if (mounted) Navigator.of(context).pop();
  }

  /// Empty saves no budget; anything else must be an amount above 0.
  void _submit(String currency) {
    final typed = parseBudget(_amount.text, currency);
    if (_amount.text.trim().isEmpty) {
      _save(null);
    } else if (typed == null) {
      setState(() => _error = context.l10n.budgetSheetInvalid);
    } else {
      _save(typed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final inputs = ref.watch(budgetInputsProvider(_today)).value;
    if (inputs == null) return const SizedBox(height: 200);
    final currency = inputs.currency;
    if (!_filled) {
      _filled = true;
      _amount.text = majorText(inputs.budget, currency);
    }
    final typed = parseBudget(_amount.text, currency);
    final small = EbbType.small.copyWith(color: c.ink2);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          const BudgetSheetTitle(),
          BudgetAmountField(
            controller: _amount,
            currency: currency,
            error: _error,
            onChanged: (_) => setState(() => _error = null),
          ),
          PresetChips(
            values: budgetPresets(inputs.monthly.minor, currency),
            currency: currency,
            selected: typed,
            onPicked: (minor) => setState(() {
              _amount.text = majorText(minor, currency);
              _error = null;
            }),
          ),
          BudgetPreview(inputs: inputs, budget: typed),
          Text(
            '${l10n.budgetSheetWarnNote}\n${l10n.budgetSheetCurrencyNote(currency)}',
            style: small,
          ),
          Row(
            spacing: 8,
            children: [
              if (inputs.budget != null)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: c.danger),
                  onPressed: () => _save(null),
                  child: Text(l10n.budgetSheetClear),
                ),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: () => _submit(currency),
                  child: Text(
                    MaterialLocalizations.of(context).saveButtonLabel,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
