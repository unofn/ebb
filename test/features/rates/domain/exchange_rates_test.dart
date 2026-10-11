import 'package:decimal/decimal.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Decimal d(String s) => Decimal.parse(s);
  final rates = ExchangeRates(
    'CNY',
    rates: {'USD': d('0.14'), 'JPY': d('21.0'), 'EUR': d('0.128')},
  );

  test('the base is always 1, overrides win, unknown is null', () {
    expect(rates.rateOf('CNY'), Decimal.one);
    expect(rates.rateOf('usd'), d('0.14'));
    final overridden = rates.copyWith(overrides: {'USD': d('0.15')});
    expect(overridden.rateOf('USD'), d('0.15'));
    expect(rates.rateOf('GBP'), isNull);
  });

  group('convertMinor', () {
    test('same currency returns the amount unchanged', () {
      expect(rates.convertMinor(1234, 'GBP', 'gbp'), 1234);
    });

    test('to and from the base, rounding half up to minor units', () {
      // $1.00 / 0.14 = ¥7.142857… → 714
      expect(rates.convertMinor(100, 'USD', 'CNY'), 714);
      // ¥10.00 × 0.14 = $1.40
      expect(rates.convertMinor(1000, 'CNY', 'USD'), 140);
      // ¥0.25 × 0.14 = $0.035 → $0.04 (half up)
      expect(rates.convertMinor(25, 'CNY', 'USD'), 4);
    });

    test('JPY has no minor digits', () {
      // ¥12.34 CNY × 21 = 259.14 JPY → 259
      expect(rates.convertMinor(1234, 'CNY', 'JPY'), 259);
      // 1000 JPY / 21 = ¥47.619… → 4762
      expect(rates.convertMinor(1000, 'JPY', 'CNY'), 4762);
      // ¥0.50 × 21 = 10.5 JPY → 11
      expect(rates.convertMinor(50, 'CNY', 'JPY'), 11);
    });

    test('cross rates go through the base', () {
      // $10.00 × 0.128 / 0.14 = €9.142857… → 914
      expect(rates.convertMinor(1000, 'USD', 'EUR'), 914);
    });

    test('an override changes the result', () {
      final overridden = rates.copyWith(overrides: {'USD': d('0.125')});
      expect(overridden.convertMinor(100, 'USD', 'CNY'), 800);
    });

    test('a missing rate gives null', () {
      expect(rates.convertMinor(100, 'GBP', 'CNY'), isNull);
      expect(rates.convertMinor(100, 'CNY', 'GBP'), isNull);
      expect(
        const ExchangeRates('CNY').convertMinor(100, 'USD', 'CNY'),
        isNull,
      );
    });
  });
}
