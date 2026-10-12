import 'package:ebb/app/format/money_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drops all-zero decimals only', () {
    expect(compactMoneyText(2500, 'CNY'), '¥25');
    expect(compactMoneyText(2550, 'CNY'), '¥25.50');
    expect(compactMoneyText(1234500, 'USD'), '\$12,345');
    expect(compactMoneyText(1500, 'JPY'), '¥1,500', reason: 'no decimals');
  });
}
