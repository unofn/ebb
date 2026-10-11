import 'package:ebb/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decimal digits follow the currency', () {
    expect(toMinor(217.66, 'CNY'), 21766);
    expect(toMinor(9.99, 'USD'), 999);
    expect(toMinor(1490, 'RUB'), 149000);
    expect(toMinor(199.5, 'INR'), 19950);
    expect(toMinor(1200, 'JPY'), 1200);
  });

  test('rounds to the minor unit', () {
    expect(toMinor(12.3456, 'USD'), 1235);
    expect(toMinor(99.6, 'JPY'), 100);
  });

  test('codes are case-insensitive', () {
    expect(isKnownCurrency('usd'), isTrue);
    expect(toMinor(1.5, 'cny'), 150);
  });

  test('unknown codes are flagged and use 2 digits', () {
    expect(isKnownCurrency('RMB'), isFalse);
    expect(isKnownCurrency('CNY'), isTrue);
    expect(currencyOf('ZZZ').decimalDigits, 2);
    expect(toMinor(3.14, 'ZZZ'), 314);
  });
}
