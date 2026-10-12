import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';
import 'package:ebb/features/stats/domain/future_months.dart';
import 'package:ebb/features/subscriptions/domain/money_total.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  final today = utcDate(2026, 10, 12);
  final rates = ExchangeRates('CNY', rates: {'USD': Decimal.parse('0.125')});

  List<int> personal(List<Subscription> subs) => [
    for (final m in futureMonths(subs, today: today, rates: rates, base: 'CNY'))
      m.personal.minor,
  ];

  test('12 months from this one, charges after today only', () {
    final months = futureMonths(
      [
        fakeSubscription(
          startDate: utcDate(2026, 1, 15),
          nextDate: utcDate(2026, 10, 15),
        ),
      ],
      today: today,
      rates: rates,
      base: 'CNY',
    );
    expect(months.first.month, utcDate(2026, 10, 1));
    expect(months.last.month, utcDate(2027, 9, 1));
    expect(months.map((m) => m.personal.minor), List.filled(12, 1200));
  });

  test('an unconfirmed manual renewal counts from its next occurrence', () {
    final manual = fakeSubscription(
      autoRenew: false,
      startDate: utcDate(2026, 9, 5),
      nextDate: utcDate(2026, 10, 5),
    );
    expect(personal([manual]), [0, ...List.filled(11, 1200)]);
  });

  test('yearly charges land in their month, converted at today\'s rate', () {
    final yearly = fakeSubscription(
      priceMinor: 12000,
      currency: 'USD',
      cycleUnit: CycleUnit.year,
      startDate: utcDate(2026, 3, 1),
      nextDate: utcDate(2027, 3, 1),
    );
    // $120 ÷ 0.125 = ¥960，落在 2027 年 3 月（第 6 个月）。
    expect(personal([yearly]), [0, 0, 0, 0, 0, 96000, 0, 0, 0, 0, 0, 0]);
  });

  test('trials count from their end; intro price and my share apply', () {
    final trial = fakeSubscription(
      priceMinor: 3000,
      startDate: utcDate(2026, 10, 1),
      nextDate: utcDate(2026, 11, 1),
    ).copyWith(trialEndsOn: Value(utcDate(2026, 11, 1)));
    final intro =
        fakeSubscription(
          startDate: utcDate(2026, 9, 10),
          nextDate: utcDate(2026, 11, 10),
        ).copyWith(
          introPriceMinor: const Value(600),
          introEndsOn: Value(utcDate(2027, 1, 10)),
        );
    final shared = fakeSubscription(
      startDate: utcDate(2026, 1, 20),
      nextDate: utcDate(2026, 10, 20),
    ).copyWith(myShareMinor: const Value(400));
    expect(personal([trial]), [0, ...List.filled(11, 3000)]);
    expect(personal([intro]), [0, 600, 600, ...List.filled(9, 1200)]);
    expect(personal([shared]), List.filled(12, 400));
  });

  test('an ending subscription only charges before its end date', () {
    Subscription ending(DateTime endDate) => fakeSubscription(
      status: SubscriptionStatus.ending,
      startDate: utcDate(2026, 1, 20),
      nextDate: utcDate(2026, 10, 20),
    ).copyWith(endDate: Value(endDate));
    // 预付到 12 月 20 日：10、11 月还会扣。
    expect(personal([ending(utcDate(2026, 12, 20))]), [
      1200,
      1200,
      ...List.filled(10, 0),
    ]);
    // 通常 end_date 就是 next_date：不再扣费。
    expect(personal([ending(utcDate(2026, 10, 20))]), List.filled(12, 0));
  });

  test(
    'only active and ending recurring rows; reimbursed and unconverted apart',
    () {
      final next = utcDate(2026, 10, 20);
      final reimbursed = fakeSubscription(
        id: 'r',
        nextDate: next,
      ).copyWith(reimbursed: true);
      final gbp = fakeSubscription(id: 'g', currency: 'GBP', nextDate: next);
      final skipped = [
        fakeSubscription(status: SubscriptionStatus.paused, nextDate: next),
        fakeSubscription(status: SubscriptionStatus.cancelled, nextDate: next),
        fakeSubscription(nextDate: next)
            .copyWith(kind: SubscriptionKind.oneTime),
        fakeSubscription(nextDate: next).copyWith(deleted: true),
      ];
      final first = futureMonths(
        [reimbursed, gbp, ...skipped],
        today: today,
        rates: rates,
        base: 'CNY',
      ).first;
      expect(
        first.personal,
        const MoneyTotal('CNY', 0, unconverted: {'GBP': 1200}),
      );
      expect(first.reimbursed, const MoneyTotal('CNY', 1200));
      expect(first.missingRates, {'GBP'});
    },
  );
}
