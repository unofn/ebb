import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/payments/domain/auto_payments.dart';
import 'package:ebb/features/payments/domain/due_payment.dart';
import 'package:ebb/features/payments/domain/payment_run.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';
import 'payment_run_helpers.dart';

void main() {
  final rates = ExchangeRates('CNY', rates: {'USD': Decimal.parse('0.125')});
  PaymentRun run(sub, DateTime today, [Set<String> existing = const {}]) =>
      autoPayments(
        sub,
        today: today,
        existingPaymentIds: existing,
        rateOf: rates.rateOf,
      );

  test('month ends clamp from the anchor', () {
    final sub = fakeSubscription(
      startDate: utcDate(2024, 1, 31),
      nextDate: utcDate(2024, 2, 29),
    );
    final result = run(sub, utcDate(2024, 4, 1));
    expect(paidOf(result), [
      (utcDate(2024, 2, 29), 1200),
      (utcDate(2024, 3, 31), 1200),
    ]);
    expect(result.patch!.nextDate.value, utcDate(2024, 4, 30));
    final first = result.payments.first;
    expect(first.id.value, paymentIdFor(sub.id, utcDate(2024, 2, 29)));
    expect(first.origin.value, PaymentOrigin.auto);
    expect(first.rateToBase.value, '1');
    expect(first.subscriptionId.value, sub.id);
  });

  test('a trial sets the next date to its end, then pays from there', () {
    final sub = fakeSubscription(startDate: utcDate(2026, 10, 1))
        .copyWith(trialEndsOn: Value(utcDate(2026, 10, 8)));
    final during = run(sub, utcDate(2026, 10, 5));
    expect(during.payments, isEmpty);
    expect(during.patch!.nextDate.value, utcDate(2026, 10, 8));

    final after = run(applied(sub, during), utcDate(2026, 11, 10));
    expect(paidOf(after), [
      (utcDate(2026, 10, 8), 1200),
      (utcDate(2026, 11, 8), 1200),
    ]);
    expect(after.patch!.nextDate.value, utcDate(2026, 12, 8));
  });

  test('intro price, then the full price', () {
    final sub =
        fakeSubscription(
          startDate: utcDate(2026, 7, 1),
          nextDate: utcDate(2026, 7, 1),
        ).copyWith(
          introPriceMinor: const Value(100),
          introEndsOn: Value(utcDate(2026, 9, 1)),
        );
    expect(paidOf(run(sub, utcDate(2026, 10, 1))), [
      (utcDate(2026, 7, 1), 100),
      (utcDate(2026, 8, 1), 100),
      (utcDate(2026, 9, 1), 1200),
      (utcDate(2026, 10, 1), 1200),
    ]);
  });

  test('my share, in the original currency with its rate', () {
    final sub = fakeSubscription(
      priceMinor: 3000,
      currency: 'USD',
      startDate: utcDate(2026, 9, 11),
      nextDate: utcDate(2026, 10, 11),
    ).copyWith(myShareMinor: const Value(1000));
    final payment = run(sub, utcDate(2026, 10, 11)).payments.single;
    expect(payment.amountMinor.value, 1000);
    expect(payment.currency.value, 'USD');
    expect(payment.rateToBase.value, '0.125');
    final noRate = autoPayments(
      sub,
      today: utcDate(2026, 10, 11),
      existingPaymentIds: const {},
      rateOf: const ExchangeRates('CNY').rateOf,
    );
    expect(noRate.payments.single.rateToBase.value, isNull);
  });

  test('a moved billing day is kept', () {
    final sub = fakeSubscription(
      startDate: utcDate(2026, 1, 10),
      nextDate: utcDate(2026, 10, 20),
    );
    final result = run(sub, utcDate(2026, 11, 25));
    expect(paidOf(result).map((p) => p.$1), [
      utcDate(2026, 10, 20),
      utcDate(2026, 11, 20),
    ]);
    expect(result.patch!.nextDate.value, utcDate(2026, 12, 20));
  });

  test('a next date in the future is left alone', () {
    final sub = fakeSubscription(
      startDate: utcDate(2026, 1, 10),
      nextDate: utcDate(2026, 12, 10),
    );
    expect(run(sub, utcDate(2026, 10, 11)).isEmpty, isTrue);
  });

  test('paused, cancelled, one-time and deleted rows do not move', () {
    final sub = fakeSubscription(
      startDate: utcDate(2026, 1, 1),
      nextDate: utcDate(2026, 9, 1),
    );
    for (final row in [
      sub.copyWith(status: SubscriptionStatus.paused),
      sub.copyWith(status: SubscriptionStatus.cancelled),
      sub.copyWith(kind: SubscriptionKind.oneTime),
      sub.copyWith(deleted: true),
      sub.copyWith(cycleUnit: const Value(null)),
    ]) {
      expect(run(row, utcDate(2026, 10, 11)).isEmpty, isTrue);
    }
  });
}
