import 'package:ebb/features/subscriptions/ui/edit/form/amount_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses major units into minor units of the currency', () {
    expect(parseMinor('15.49', 'USD'), 1549);
    expect(parseMinor(' 15,5 ', 'EUR'), 1550);
    expect(parseMinor('.5', 'CNY'), 50);
    expect(parseMinor('1200', 'JPY'), 1200);
    expect(parseMinor('-3', 'CNY'), -300);
  });

  test('blank and non-numbers parse as null', () {
    for (final text in ['', ' ', 'abc', 'NaN', 'Infinity', '1.2.3', '1e3']) {
      expect(parseMinor(text, 'USD'), isNull, reason: text);
    }
  });

  test('formats minor units without symbol or grouping', () {
    expect(minorInput(1549, 'USD'), '15.49');
    expect(minorInput(5, 'CNY'), '0.05');
    expect(minorInput(123456, 'CNY'), '1234.56');
    expect(minorInput(1200, 'JPY'), '1200');
    expect(minorInput(-150, 'USD'), '-1.50');
  });
}
