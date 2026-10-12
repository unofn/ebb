import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';

/// The sheet's handle, title and what the budget is compared with.
class BudgetSheetTitle extends StatelessWidget {
  const BudgetSheetTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: c.lineStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text(
          l10n.budgetSheetTitle,
          style: EbbType.body.copyWith(
            color: c.ink,
            fontWeight: EbbType.strong,
          ),
        ),
        Text(
          l10n.budgetSheetSubtitle,
          style: EbbType.small.copyWith(color: c.ink2),
        ),
      ],
    );
  }
}
