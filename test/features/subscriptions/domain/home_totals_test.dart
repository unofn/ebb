import 'package:decimal/decimal.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';
import 'package:ebb/features/subscriptions/domain/home_totals.dart';
import 'package:ebb/features/subscriptions/domain/money_total.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  final today = utcDate(2026, 10, 11);
  final rates = ExchangeRates('CNY', rates: {'USD': Decimal.parse('0.125')});

  test('monthly in the base currency, missing rates listed apart', () {
    final subs = [
      fakeSubscription(id: 'a', priceMinor: 1200),
      fakeSubscription(
        id: 'b',
        priceMinor: 12000,
        currency: 'USD',
        cycleUnit: CycleUnit.year,
      ),
      fakeSubscription(id: 'c', priceMinor: 300, currency: 'GBP'),
      fakeSubscription(id: 'd', priceMinor: 200, currency: 'gbp'),
      fakeSubscription(id: 'e', status: SubscriptionStatus.ending),
    ];
    final totals = homeTotals(
      subs,
      today: today,
      baseCurrency: 'CNY',
      rates: rates,
    );
    // ¥12.00 + $10.00/月 ÷ 0.125 = ¥92.00；到期不续不计入
    expect(
      totals.monthly,
      const MoneyTotal('CNY', 9200, unconverted: {'GBP': 500}),
    );
    expect(
      totals.yearly,
      const MoneyTotal('CNY', 110400, unconverted: {'GBP': 6000}),
    );
  });

  test('no subscriptions sum to zero', () {
    final totals = homeTotals(
      const [],
      today: today,
      baseCurrency: 'CNY',
      rates: const ExchangeRates('CNY'),
    );
    expect(totals.monthly, const MoneyTotal('CNY', 0));
  });
}
