import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/payments/domain/auto_payments.dart';
import 'package:ebb/features/payments/domain/due_payment.dart';
import 'package:ebb/features/payments/domain/mark_paid.dart';
import 'package:ebb/features/payments/domain/payment_run.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';
import 'package:ebb/features/subscriptions/domain/subscription_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';
import 'payment_run_helpers.dart';

void main() {
  const rates = ExchangeRates('CNY');
  PaymentRun run(sub, DateTime today, [Set<String> existing = const {}]) =>
      autoPayments(
        sub,
        today: today,
        existingPaymentIds: existing,
        rates: rates,
      );

  group('ending', () {
    final sub = fakeSubscription(
      startDate: utcDate(2026, 1, 15),
      nextDate: utcDate(2026, 9, 15),
      status: SubscriptionStatus.ending,
    ).copyWith(endDate: Value(utcDate(2026, 10, 15)));

    test('pays before the end date; no next date at the end', () {
      final result = run(sub, utcDate(2026, 10, 14));
      expect(paidOf(result).map((p) => p.$1), [utcDate(2026, 9, 15)]);
      expect(result.patch, const SubscriptionsCompanion(nextDate: Value(null)));
    });

    test('is cancelled exactly on the end date, without paying it', () {
      final result = run(sub, utcDate(2026, 10, 15));
      expect(paidOf(result).map((p) => p.$1), [utcDate(2026, 9, 15)]);
      expect(result.patch!.status.value, SubscriptionStatus.cancelled);
      expect(result.patch!.nextDate.value, isNull);
    });

    test('runs on the next days add nothing, then it is cancelled', () {
      final first = run(sub, utcDate(2026, 10, 14));
      final ids = {for (final p in first.payments) p.id.value};
      final noNext = applied(sub, first);
      expect(run(noNext, utcDate(2026, 10, 14), ids).isEmpty, isTrue);
      final ended = run(noNext, utcDate(2026, 10, 15), ids);
      expect(ended.payments, isEmpty);
      expect(ended.patch!.status.value, SubscriptionStatus.cancelled);
      expect(
        run(applied(noNext, ended), utcDate(2026, 10, 16)).isEmpty,
        isTrue,
      );
    });

    test('imported without a next date: no backfill from the start', () {
      final imported = sub.copyWith(nextDate: const Value(null));
      expect(run(imported, utcDate(2026, 10, 14)).isEmpty, isTrue);
    });

    test('a manual one is cancelled too, without payments', () {
      final result = run(sub.copyWith(autoRenew: false), utcDate(2026, 11, 1));
      expect(result.payments, isEmpty);
      expect(result.patch!.status.value, SubscriptionStatus.cancelled);
    });
  });

  group('idempotency', () {
    final sub = fakeSubscription(
      startDate: utcDate(2026, 6, 1),
      nextDate: utcDate(2026, 8, 1),
    );
    final today = utcDate(2026, 10, 11);

    test('running on the result adds nothing', () {
      final first = run(sub, today);
      expect(first.payments, hasLength(3));
      final ids = {for (final p in first.payments) p.id.value};
      expect(run(applied(sub, first), today, ids).isEmpty, isTrue);
    });

    test('existing IDs are skipped even before next_date moves', () {
      final ids = {
        for (final day in [8, 9, 10])
          paymentIdFor(sub.id, utcDate(2026, day, 1)),
      };
      final again = run(sub, today, ids);
      expect(again.payments, isEmpty);
      expect(again.patch!.nextDate.value, utcDate(2026, 11, 1));
    });

    test('a soft-deleted payment is not generated again', () {
      final deletedId = paymentIdFor(sub.id, utcDate(2026, 9, 1));
      final result = run(sub, today, {deletedId});
      expect(paidOf(result).map((p) => p.$1), [
        utcDate(2026, 8, 1),
        utcDate(2026, 10, 1),
      ]);
    });
  });

  test('an active row without next date or trial is left alone', () {
    final sub = fakeSubscription(startDate: utcDate(2026, 1, 1));
    expect(run(sub, utcDate(2026, 10, 11)).isEmpty, isTrue);
  });

  test('manual renewal waits for confirmation, then markPaid', () {
    final today = utcDate(2026, 10, 11);
    final sub = fakeSubscription(
      startDate: utcDate(2026, 1, 1),
      nextDate: utcDate(2026, 10, 1),
      autoRenew: false,
    );
    expect(run(sub, today).isEmpty, isTrue);
    expect(sub.isAwaitingConfirmation(today), isTrue);

    final paid = markPaid(sub, utcDate(2026, 10, 1), rates: rates);
    final payment = paid.payments.single;
    expect(payment.origin.value, PaymentOrigin.manual);
    expect(payment.id.value, paymentIdFor(sub.id, utcDate(2026, 10, 1)));
    expect(payment.amountMinor.value, 1200);
    expect(payment.baseCurrency.value, 'CNY');
    final after = applied(sub, paid);
    expect(after.nextDate, utcDate(2026, 11, 1));
    expect(after.isAwaitingConfirmation(today), isFalse);
  });
}
