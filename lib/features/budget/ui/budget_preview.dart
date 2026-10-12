import 'package:flutter/material.dart';

import '../../../app/format/money_text.dart';
import '../../../app/format/total_text.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/budget_meter.dart';
import '../domain/budget_status.dart';
import 'budget_inputs.dart';

/// The monthly average against the amount being typed: share, bar and
/// what is left or over.
class BudgetPreview extends StatelessWidget {
  const BudgetPreview({super.key, required this.inputs, required this.budget});

  final BudgetInputs inputs;

  /// Minor units of the base currency; null for none.
  final int? budget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final status = budgetStatus(inputs.monthly.minor, budget);
    final color = switch (status?.level) {
      null => c.ink2,
      BudgetLevel.normal => c.accent,
      BudgetLevel.near => c.warn,
      BudgetLevel.over => c.danger,
    };
    String money(int minor) => moneyText(minor, inputs.currency);
    final body = EbbType.body.tabular.copyWith(color: c.ink);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.budgetSheetCurrent(
                    totalText(
                      l10n,
                      inputs.monthly,
                      converted: inputs.converted,
                    ),
                  ),
                  style: body,
                ),
              ),
              Text(
                status == null
                    ? l10n.budgetSheetUnset
                    : l10n.budgetSheetShare((status.ratio * 100).round()),
                style: body.copyWith(color: color, fontWeight: EbbType.strong),
              ),
            ],
          ),
          if (status != null) BudgetMeter(status: status, height: 6),
          Text(
            switch (status?.level) {
              null => l10n.budgetSheetNone,
              BudgetLevel.normal => l10n.budgetSheetLeft(
                money(status!.remaining),
              ),
              BudgetLevel.near => l10n.budgetSheetNear(
                money(status!.remaining),
              ),
              BudgetLevel.over => l10n.budgetSheetOver(
                money(-status!.remaining),
              ),
            },
            style: EbbType.small.copyWith(
              color: status == null || status.level == BudgetLevel.normal
                  ? c.ink2
                  : color,
            ),
          ),
        ],
      ),
    );
  }
}
