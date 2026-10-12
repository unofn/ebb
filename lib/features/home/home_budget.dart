import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/format/money_text.dart';
import '../../app/l10n/l10n.dart';
import '../../app/theme/ebb_colors.dart';
import '../../app/theme/ebb_type.dart';
import '../../app/widgets/budget_meter.dart';
import '../budget/domain/budget_status.dart';
import '../budget/ui/budget_sheet.dart';

/// 「预算 ¥400 · 已用 80%」 (or 「超出 ¥36.20」), colored by level; opens
/// the budget sheet. Sits at the end of the yearly line.
class HomeBudgetText extends StatelessWidget {
  const HomeBudgetText({
    super.key,
    required this.status,
    required this.currency,
  });

  final BudgetStatus status;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final level = status.level;
    final text = level == BudgetLevel.over
        ? l10n.homeBudgetOver(moneyText(-status.remaining, currency))
        : l10n.homeBudgetUsed(
            compactMoneyText(status.budget, currency),
            (status.ratio * 100).round(),
          );
    return GestureDetector(
      onTap: () => unawaited(showBudgetSheet(context)),
      child: Text(
        text,
        style: EbbType.small.tabular.copyWith(
          color: level == BudgetLevel.normal ? c.ink2 : budgetColor(c, level),
          fontWeight: level == BudgetLevel.normal ? null : EbbType.strong,
        ),
      ),
    );
  }
}

/// The 4-high budget bar under the yearly line; opens the budget sheet.
class HomeBudgetBar extends StatelessWidget {
  const HomeBudgetBar({super.key, required this.status});

  final BudgetStatus status;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => unawaited(showBudgetSheet(context)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: BudgetMeter(status: status),
    ),
  );
}
