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

void main() {
  final rates = ExchangeRates('CNY', rates: {'USD': Decimal.parse('0.125')});
  final today = utcDate(2026, 10, 11);
  final purchase = fakeSubscription(
    priceMinor: 2500,
    currency: 'USD',
    cycleUnit: null,
    cycleCount: null,
    startDate: utcDate(2026, 5, 20),
  ).copyWith(kind: SubscriptionKind.oneTime);
  PaymentRun run(sub, [Set<String> existing = const {}]) => autoPayments(
    sub,
    today: today,
    existingPaymentIds: existing,
    rates: rates,
  );

  test('paid once on the start date, at my share', () {
    final shared = purchase.copyWith(myShareMinor: const Value(1000));
    final result = run(shared);
    final payment = result.payments.single;
    expect(payment.id.value, paymentIdFor(purchase.id, utcDate(2026, 5, 20)));
    expect(payment.paidOn.value, utcDate(2026, 5, 20));
    expect(payment.amountMinor.value, 1000);
    expect(payment.currency.value, 'USD');
    expect(payment.origin.value, PaymentOrigin.auto);
    expect(payment.rateToBase.value, '0.125');
    expect(payment.baseCurrency.value, 'CNY');
    expect(result.patch, isNull);
  });

  test('a purchase made today counts; one still ahead does not', () {
    expect(
      run(purchase.copyWith(startDate: Value(today))).payments,
      hasLength(1),
    );
    final ahead = purchase.copyWith(startDate: Value(utcDate(2026, 10, 12)));
    expect(run(ahead).isEmpty, isTrue);
  });

  test('any existing payment, even an imported or deleted one, skips it', () {
    expect(run(purchase, {'imported-payment-id'}).isEmpty, isTrue);
  });

  test('no start date, cancelled or deleted: nothing', () {
    for (final row in [
      purchase.copyWith(startDate: const Value(null)),
      purchase.copyWith(status: SubscriptionStatus.cancelled),
      purchase.copyWith(deleted: true),
    ]) {
      expect(run(row).isEmpty, isTrue);
    }
  });
}
