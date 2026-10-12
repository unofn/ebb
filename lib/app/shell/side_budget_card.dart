import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/local_date.dart';
import '../../features/budget/ui/budget_sheet.dart';
import '../format/money_text.dart';
import '../l10n/l10n.dart';
import '../providers/budget_providers.dart';
import '../providers/repository_providers.dart';
import '../theme/ebb_colors.dart';
import '../theme/ebb_type.dart';
import '../widgets/budget_meter.dart';

/// The sidebar's 「每月预算 ¥318.16 / ¥400」 with its bar; opens the budget
/// sheet. Nothing without a budget.
class SideBudgetCard extends ConsumerWidget {
  const SideBudgetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(budgetStatusOnProvider(today())).value;
    final base = ref.watch(baseCurrencyProvider).value;
    if (status == null || base == null) return const SizedBox.shrink();
    final c = context.colors;
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(
                context.l10n.statsBudget,
                style: EbbType.small.copyWith(color: c.ink2),
              ),
              Text(
                '${moneyText(status.used, base)} / '
                '${compactMoneyText(status.budget, base)}',
                style: EbbType.body.tabular.copyWith(
                  color: c.ink,
                  fontWeight: EbbType.strong,
                ),
              ),
              BudgetMeter(status: status),
            ],
          ),
        ),
      ),
    );
  }
}
