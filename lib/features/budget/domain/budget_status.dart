import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_status.freezed.dart';

/// How close the monthly average is to the budget.
enum BudgetLevel {
  normal,

  /// 90 % of the budget or more.
  near,

  /// More than the budget.
  over,
}

/// The monthly average measured against a monthly budget, both in minor
/// units of the base currency.
@freezed
abstract class BudgetStatus with _$BudgetStatus {
  const factory BudgetStatus({
    /// The home screen's monthly average.
    required int used,
    required int budget,
  }) = _BudgetStatus;

  const BudgetStatus._();

  /// Below zero when over budget.
  int get remaining => budget - used;

  /// [used] ÷ [budget]; 1.0 = all of it.
  double get ratio => used / budget;

  // 用整数比较，避免 0.9 的浮点误差。
  BudgetLevel get level => used > budget
      ? BudgetLevel.over
      : used * 10 >= budget * 9
      ? BudgetLevel.near
      : BudgetLevel.normal;
}

/// [monthlyTotal] against [budget]; null when no budget is set (a budget
/// of zero or less counts as none).
BudgetStatus? budgetStatus(int monthlyTotal, int? budget) =>
    budget == null || budget <= 0
    ? null
    : BudgetStatus(used: monthlyTotal, budget: budget);
