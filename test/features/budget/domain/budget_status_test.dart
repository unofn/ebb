import 'package:ebb/features/budget/domain/budget_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('used, remaining and ratio against the budget', () {
    final status = budgetStatus(31816, 40000)!;
    expect(status.used, 31816);
    expect(status.remaining, 8184);
    expect(status.ratio, closeTo(0.7954, 0.0001));
    expect(status.level, BudgetLevel.normal);
  });

  test('near from 90 %, over only above 100 %', () {
    expect(budgetStatus(35999, 40000)!.level, BudgetLevel.normal);
    expect(budgetStatus(36000, 40000)!.level, BudgetLevel.near);
    expect(budgetStatus(40000, 40000)!.level, BudgetLevel.near);
    expect(budgetStatus(40001, 40000)!.level, BudgetLevel.over);
    expect(budgetStatus(45000, 40000)!.remaining, -5000);
  });

  test('no budget, or one of zero, gives no status', () {
    expect(budgetStatus(31816, null), isNull);
    expect(budgetStatus(31816, 0), isNull);
  });
}
