import 'package:flutter/material.dart';

import '../../features/budget/domain/budget_status.dart';
import '../theme/ebb_colors.dart';

/// The budget's color: the accent while fine, amber from 90%, red over.
Color budgetColor(EbbColors c, BudgetLevel level) => switch (level) {
  BudgetLevel.normal => c.accent,
  BudgetLevel.near => c.warn,
  BudgetLevel.over => c.danger,
};

/// How much of the budget the monthly average uses, as a thin bar
/// ([height] 4 on home and in the sidebar, 6 in statistics); full when over.
class BudgetMeter extends StatelessWidget {
  const BudgetMeter({super.key, required this.status, this.height = 4});

  final BudgetStatus status;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(height / 2);
    return Container(
      height: height,
      decoration: BoxDecoration(color: c.surface2, borderRadius: radius),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: status.ratio.clamp(0.0, 1.0),
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: budgetColor(c, status.level),
            borderRadius: radius,
          ),
        ),
      ),
    );
  }
}
