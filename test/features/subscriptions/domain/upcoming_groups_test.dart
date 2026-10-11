import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';
import 'package:ebb/features/subscriptions/domain/money_total.dart';
import 'package:ebb/features/subscriptions/domain/upcoming_groups.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  // 2026-10-29 是周四；本周（周一起）到 11 月 1 日周日。
  final today = utcDate(2026, 10, 29);

  group('periodOf across a month boundary', () {
    test('this week runs into next month', () {
      expect(periodOf(utcDate(2026, 10, 27), today), const ThisWeek());
      expect(periodOf(today, today), const ThisWeek());
      expect(periodOf(utcDate(2026, 11, 1), today), const ThisWeek());
      expect(periodOf(utcDate(2026, 11, 2), today), const InMonth(2026, 11));
      expect(periodOf(utcDate(2027, 1, 5), today), const InMonth(2027, 1));
    });

    test('later this month after this week', () {
      final mid = utcDate(2026, 10, 14); // 周三，本周到 10 月 18 日
      expect(periodOf(utcDate(2026, 10, 18), mid), const ThisWeek());
      expect(periodOf(utcDate(2026, 10, 19), mid), const LaterThisMonth());
      expect(periodOf(utcDate(2026, 10, 31), mid), const LaterThisMonth());
    });

    test('weeks can start on Sunday', () {
      expect(
        periodOf(utcDate(2026, 11, 1), today, weekStart: DateTime.sunday),
        const InMonth(2026, 11),
      );
    });
  });

  test('groups in date order with totals in the base currency', () {
    final rates = ExchangeRates('CNY', rates: {'USD': Decimal.parse('0.125')});
    final overdue = fakeSubscription(
      id: 'overdue',
      autoRenew: false,
      nextDate: utcDate(2026, 10, 20),
    );
    final usd = fakeSubscription(
      id: 'usd',
      currency: 'USD',
      priceMinor: 1000,
      nextDate: utcDate(2026, 10, 31),
    );
    final gbp = fakeSubscription(
      id: 'gbp',
      currency: 'GBP',
      priceMinor: 500,
      nextDate: utcDate(2026, 11, 5),
    );
    final trial = fakeSubscription(
      id: 'trial',
      nextDate: utcDate(2026, 11, 20),
    ).copyWith(trialEndsOn: Value(utcDate(2026, 11, 21)));
    final groups = upcomingGroups(
      [gbp, trial, usd, overdue],
      today: today,
      baseCurrency: 'CNY',
      rates: rates,
    );
    expect(groups.map((g) => g.period), [
      const ThisWeek(),
      const InMonth(2026, 11),
    ]);
    expect(groups[0].subscriptions.map((s) => s.id), ['overdue', 'usd']);
    // ¥12.00 + $10.00 / 0.125
    expect(groups[0].total, const MoneyTotal('CNY', 9200));
    expect(groups[1].subscriptions.map((s) => s.id), ['gbp', 'trial']);
    expect(
      groups[1].total,
      const MoneyTotal('CNY', 0, unconverted: {'GBP': 500}),
    );
  });
}
