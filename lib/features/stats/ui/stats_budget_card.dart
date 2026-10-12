import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format/money_text.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/providers/budget_providers.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/budget_meter.dart';
import '../../budget/domain/budget_status.dart';
import '../../budget/ui/budget_sheet.dart';

/// The monthly budget against the monthly average, with what is left (or
/// over); 「还没设预算」 until one is set. Tapping it (or 「调整」 on the
/// desktop) opens the budget sheet.
class StatsBudgetCard extends ConsumerWidget {
  const StatsBudgetCard({
    super.key,
    required this.today,
    required this.currency,
    this.wide = false,
  });

  final DateTime today;
  final String currency;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final status = ref.watch(budgetStatusOnProvider(today)).value;
    final small = EbbType.small.tabular.copyWith(color: c.ink2);
    final body = EbbType.body.tabular.copyWith(color: c.ink);
    final title = Text(
      l10n.statsBudget,
      style: body.copyWith(fontWeight: EbbType.strong),
    );
    final usage = status == null
        ? l10n.statsBudgetUnset
        : '${moneyText(status.used, currency)} / ${compactMoneyText(status.budget, currency)}';
    final action = Text(
      status == null ? l10n.statsBudgetSet : l10n.statsBudgetAdjust,
      style: small.copyWith(color: c.accent, fontWeight: EbbType.strong),
    );
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => unawaited(showBudgetSheet(context)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Row(
                children: [
                  Expanded(child: title),
                  if (wide || status == null)
                    action
                  else
                    Text(usage, style: body),
                ],
              ),
              if (wide || status == null)
                Text(usage, style: wide ? body : small),
              if (status != null) ...[
                BudgetMeter(status: status, height: 6),
                Text(
                  status.level == BudgetLevel.over
                      ? l10n.statsBudgetOver(
                          moneyText(-status.remaining, currency),
                        )
                      : l10n.statsBudgetLeft(
                          moneyText(status.remaining, currency),
                        ),
                  style: small.copyWith(
                    color: status.level == BudgetLevel.normal
                        ? c.ink2
                        : budgetColor(c, status.level),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
