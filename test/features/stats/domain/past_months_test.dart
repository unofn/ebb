import 'package:decimal/decimal.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';
import 'package:ebb/features/stats/domain/month_spend.dart';
import 'package:ebb/features/stats/domain/past_months.dart';
import 'package:ebb/features/subscriptions/domain/money_total.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';
import '../../../support/fake_rows.dart';

void main() {
  final today = utcDate(2026, 10, 12);
  final rates = ExchangeRates('CNY', rates: {'USD': Decimal.parse('0.14')});
  final subs = [
    fakeSubscription(id: 'video'),
    fakeSubscription(id: 'work').copyWith(reimbursed: true),
    fakeSubscription(id: 'app').copyWith(kind: SubscriptionKind.oneTime),
    fakeSubscription(id: 'gone').copyWith(deleted: true),
  ];

  List<MonthSpend> spendOf(List<Payment> payments) =>
      pastMonths(payments, subs, today: today, rates: rates);

  test('the 12 months up to this one, by the month paid', () {
    final months = pastMonths(
      [
        fakePayment('a', 'video', utcDate(2025, 10, 31), 1200),
        fakePayment('b', 'video', utcDate(2025, 11, 1), 1200),
        fakePayment('c', 'video', utcDate(2026, 10, 3), 1200),
        fakePayment('d', 'video', utcDate(2026, 10, 30), 1200),
        fakePayment('e', 'video', utcDate(2026, 11, 3), 1200),
        fakePayment('f', 'app', utcDate(2026, 6, 15), 6800),
      ],
      subs,
      today: today,
      rates: rates,
    );
    expect(months.first.month, utcDate(2025, 11, 1));
    expect(months.last.month, utcDate(2026, 10, 1));
    expect(months.map((m) => m.personal.minor), [
      1200, 0, 0, 0, 0, 0, 0, 6800, 0, 0, 0, 2400, //
    ]);
  });

  test('converted at the recorded rate, else estimated or missing', () {
    final months = pastMonths(
      [
        // 记录时 1 CNY = 0.14 USD：$5.16 ≈ ¥36.86。
        fakePayment(
          'r',
          'video',
          utcDate(2026, 9, 22),
          516,
          currency: 'USD',
          rateToBase: '0.14',
          baseCurrency: 'CNY',
        ),
        // 记录时基准是美元（1 USD = 0.9 EUR），再按今天的汇率折成人民币。
        fakePayment(
          'o',
          'video',
          utcDate(2026, 5, 2),
          1000,
          currency: 'EUR',
          rateToBase: '0.9',
          baseCurrency: 'USD',
        ),
        fakePayment('t', 'video', utcDate(2026, 8, 1), 1000, currency: 'USD'),
        fakePayment('m', 'video', utcDate(2026, 7, 1), 500, currency: 'GBP'),
      ],
      subs,
      today: today,
      rates: rates,
    );
    final byMonth = {for (final m in months) m.month.month: m};
    expect(byMonth[9]!.personal, const MoneyTotal('CNY', 3686));
    expect(byMonth[9]!.estimated, isFalse);
    // €10 ÷ 0.9 ÷ 0.14 = ¥79.365…
    expect(byMonth[5]!.personal.minor, 7937);
    expect(byMonth[5]!.estimated, isTrue); // 基准货币换过，算估算
    expect(byMonth[8]!.personal.minor, 7143);
    expect(byMonth[8]!.estimated, isTrue);
    expect(
      byMonth[7]!.personal,
      const MoneyTotal('CNY', 0, unconverted: {'GBP': 500}),
    );
    expect(byMonth[7]!.missingRates, {'GBP'});
  });

  test('reimbursed apart; deleted payments and subscriptions left out', () {
    final october = spendOf([
      fakePayment('v', 'video', utcDate(2026, 10, 1), 1200),
      fakePayment('w', 'work', utcDate(2026, 10, 2), 2000),
      fakePayment('x', 'video', utcDate(2026, 10, 3), 999, deleted: true),
      fakePayment('g', 'gone', utcDate(2026, 10, 4), 888),
      fakePayment('u', 'unknown', utcDate(2026, 10, 5), 777),
    ]).last;
    expect(october.personal, const MoneyTotal('CNY', 1200));
    expect(october.reimbursed, const MoneyTotal('CNY', 2000));
  });
}
