import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';
import 'package:ebb/features/review/domain/review_due.dart';
import 'package:ebb/features/review/domain/review_queue.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  final today = utcDate(2026, 10, 12);

  test('quarters start in January, April, July and October', () {
    expect(quarterStart(utcDate(2026, 1, 1)), utcDate(2026, 1, 1));
    expect(quarterStart(utcDate(2026, 3, 31)), utcDate(2026, 1, 1));
    expect(quarterStart(utcDate(2026, 5, 20)), utcDate(2026, 4, 1));
    expect(quarterStart(today), utcDate(2026, 10, 1));
    expect(quarterStart(utcDate(2026, 12, 31)), utcDate(2026, 10, 1));
  });

  group('reviewDue', () {
    final subs = [fakeSubscription()];

    test('until completed this quarter', () {
      expect(reviewDue(subs, today: today, lastCompletedOn: null), isTrue);
      expect(
        reviewDue(subs, today: today, lastCompletedOn: utcDate(2026, 9, 30)),
        isTrue,
      );
      expect(
        reviewDue(subs, today: today, lastCompletedOn: utcDate(2026, 10, 1)),
        isFalse,
      );
    });

    test('only with an active recurring subscription', () {
      expect(reviewDue(const [], today: today, lastCompletedOn: null), isFalse);
      final idle = [
        fakeSubscription(status: SubscriptionStatus.paused),
        fakeSubscription(status: SubscriptionStatus.cancelled),
        fakeSubscription().copyWith(kind: SubscriptionKind.oneTime),
        fakeSubscription().copyWith(deleted: true),
      ];
      expect(reviewDue(idle, today: today, lastCompletedOn: null), isFalse);
    });
  });

  test('queue: active and paused, the most per month first', () {
    final rates = ExchangeRates('CNY', rates: {'USD': Decimal.parse('0.125')});
    final queue = reviewQueue(
      [
        fakeSubscription(id: 'cheap', priceMinor: 600),
        fakeSubscription(
          id: 'paused',
          priceMinor: 3000,
        ).copyWith(status: SubscriptionStatus.paused),
        fakeSubscription(id: 'usd', priceMinor: 1000, currency: 'USD'),
        fakeSubscription(
          id: 'trial',
          priceMinor: 2000,
        ).copyWith(trialEndsOn: Value(utcDate(2026, 11, 1))),
        fakeSubscription(id: 'gbp', priceMinor: 9900, currency: 'GBP'),
        fakeSubscription(
          id: 'shared',
          priceMinor: 12000,
          cycleUnit: CycleUnit.year,
        ).copyWith(myShareMinor: const Value(6000)),
        fakeSubscription(id: 'ending', status: SubscriptionStatus.ending),
        fakeSubscription(id: 'gone', status: SubscriptionStatus.cancelled),
        fakeSubscription(id: 'once').copyWith(kind: SubscriptionKind.oneTime),
      ],
      rates: rates,
      base: 'CNY',
    );
    expect(queue.map((i) => (i.subscription.id, i.baseMinor)), [
      ('usd', 8000),
      ('paused', 3000),
      ('trial', 2000),
      ('cheap', 600),
      ('shared', 500),
      ('gbp', null),
    ]);
    expect(queue.last.monthlyMinor, 9900);
  });
}
