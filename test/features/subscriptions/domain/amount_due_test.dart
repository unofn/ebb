import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/features/subscriptions/domain/amount_due.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  final sub = fakeSubscription(priceMinor: 3000);
  final day = utcDate(2026, 10, 11);

  test('the price, nothing during the trial', () {
    expect(amountFor(sub, day), 3000);
    final trial = sub.copyWith(trialEndsOn: Value(utcDate(2026, 10, 12)));
    expect(amountFor(trial, day), isNull);
    expect(amountFor(trial, utcDate(2026, 10, 12)), 3000);
  });

  test('the intro price before the offer ends, then the price', () {
    final intro = sub.copyWith(
      introPriceMinor: const Value(100),
      introEndsOn: Value(utcDate(2026, 11, 11)),
    );
    expect(amountFor(intro, day), 100);
    expect(amountFor(intro, utcDate(2026, 11, 11)), 3000);
  });

  test('my share scales both prices, rounded', () {
    final shared = sub.copyWith(
      myShareMinor: const Value(1000),
      introPriceMinor: const Value(200),
      introEndsOn: Value(utcDate(2026, 11, 11)),
    );
    expect(amountFor(shared, utcDate(2026, 12, 11)), 1000);
    // 200 × 1000 / 3000 = 66.67
    expect(amountFor(shared, day), 67);
  });

  test('nextAmountOf uses the next date', () {
    expect(nextAmountOf(sub), isNull);
    expect(nextAmountOf(sub.copyWith(nextDate: Value(day))), 3000);
  });
}
