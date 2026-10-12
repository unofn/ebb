import 'package:decimal/decimal.dart';
import 'package:ebb/features/calendar/domain/calendar_charge.dart';
import 'package:ebb/features/calendar/domain/charge_total.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarCharge _charge(int minor, String currency) => CalendarCharge(
  subscriptionId: 's',
  amountMinor: minor,
  currency: currency,
  kind: ChargeKind.paid,
);

void main() {
  final rates = ExchangeRates('CNY', rates: {'USD': Decimal.parse('0.14')});

  test('sums in the base currency; same currency is exact', () {
    final t = chargeTotal(
      [_charge(1500, 'CNY'), _charge(2500, 'cny')],
      'CNY',
      rates,
    );
    expect(t.count, 2);
    expect(t.total.minor, 4000);
    expect(t.converted, isFalse);
  });

  test('converts other currencies at today\'s rate and says so', () {
    final t = chargeTotal(
      [_charge(1400, 'USD'), _charge(100, 'CNY')],
      'CNY',
      rates,
    );
    expect(t.total.minor, 10100);
    expect(t.converted, isTrue);
  });

  test('keeps currencies without a rate apart', () {
    final t = chargeTotal(
      [_charge(500, 'EUR'), _charge(100, 'CNY')],
      'CNY',
      rates,
    );
    expect(t.total.minor, 100);
    expect(t.total.unconverted, {'EUR': 500});
    expect(t.converted, isFalse);
  });

  test('nothing is zero', () {
    final t = chargeTotal(const [], 'CNY', rates);
    expect((t.count, t.total.minor), (0, 0));
  });
}
