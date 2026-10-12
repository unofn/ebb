import 'package:ebb/features/budget/domain/budget_presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rounds the monthly average up to round steps', () {
    expect(budgetPresets(31816, 'CNY'), [35000, 40000, 45000, 60000]);
    expect(budgetPresets(8700, 'USD'), [9000, 10000, 11000, 14000]);
    expect(budgetPresets(120000, 'CNY'), [150000, 200000, 250000, 400000]);
  });

  test('an average already on a step is the first preset', () {
    expect(budgetPresets(30000, 'CNY').first, 30000);
  });

  test('uses the currency’s own minor unit', () {
    expect(budgetPresets(4800, 'JPY'), [5000, 5500, 6000, 8000]);
  });

  test('small and empty averages', () {
    expect(budgetPresets(50, 'CNY'), [100, 200, 300, 400]);
    expect(budgetPresets(0, 'CNY'), [10000, 20000, 30000, 50000]);
  });
}
