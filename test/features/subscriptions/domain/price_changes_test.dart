import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/subscriptions/domain/price_changes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  final today = utcDate(2026, 10, 11);
  final sub = fakeSubscription(
    priceMinor: 1500,
    nextDate: utcDate(2026, 11, 1),
  );

  Payment paid(int month, int amount, {bool deleted = false}) => Payment(
    id: 'p$month',
    updatedAt: '',
    deleted: deleted,
    subscriptionId: sub.id,
    paidOn: utcDate(2026, month, 1),
    amountMinor: amount,
    currency: 'CNY',
    origin: PaymentOrigin.imported,
  );

  test('a segment per amount change plus the next charge', () {
    final payments = [
      paid(4, 1200),
      paid(2, 1000),
      paid(3, 1200),
      paid(1, 1000),
    ];
    expect(priceChanges(sub, payments, today), [
      PriceSegment(
        from: utcDate(2026, 1, 1),
        amountMinor: 1000,
        currency: 'CNY',
      ),
      PriceSegment(
        from: utcDate(2026, 3, 1),
        amountMinor: 1200,
        currency: 'CNY',
        changePercent: 20,
      ),
      PriceSegment(
        from: utcDate(2026, 11, 1),
        amountMinor: 1500,
        currency: 'CNY',
        changePercent: 25,
        fromNextCharge: true,
      ),
    ]);
  });

  test('no next-charge segment when the price matches; deleted ignored', () {
    final payments = [paid(1, 1500), paid(2, 900, deleted: true)];
    expect(priceChanges(sub, payments, today), [
      PriceSegment(
        from: utcDate(2026, 1, 1),
        amountMinor: 1500,
        currency: 'CNY',
      ),
    ]);
  });

  test('my share is compared, not the full price', () {
    final shared = sub.copyWith(myShareMinor: const Value(500));
    final segments = priceChanges(shared, [paid(1, 500)], today);
    expect(segments, hasLength(1));
  });

  test('empty without payments', () {
    expect(priceChanges(sub, const [], today), isEmpty);
  });
}
