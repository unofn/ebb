import 'package:ebb/data/enums.dart';
import 'package:ebb/features/billing/cycle.dart';
import 'package:ebb/features/import/draft/import_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_tilla.dart';

// 今天固定为 2026-10-11。
void main() {
  test('monthly: one payment per month from billingDate up to today', () {
    final draft = draftOf(tillaRecord('m1'));
    expect(draft.kind, SubscriptionKind.recurring);
    expect(draft.cycle, const Cycle(CycleUnit.month, 1));
    expect(draft.startDate, isDate(2026, 1, 15));
    expect(draft.nextDate, isDate(2026, 11, 15));
    // nextBillDate 是 11/15，但 10/15 还没到，不生成。
    expect(paymentDates(draft), [
      for (var m = 1; m <= 9; m++) isDate(2026, m, 15),
    ]);
    expect(
      draft.payments.first,
      DraftPayment(
        date: draft.startDate!,
        amountMinor: 2500,
        currency: 'CNY',
        origin: PaymentOrigin.backfilled,
      ),
    );
  });

  test('yearly: one payment per year, in the record currency', () {
    final draft = draftOf(
      tillaRecord('y1', {
        'billingCycle': 'year_1',
        'price': 99.99,
        'currency': 'USD',
        'billingDate': midnight(2023, 3, 1),
        'nextBillDate': midnight(2027, 3, 1),
      }),
    );
    expect(paymentDates(draft), [
      for (var y = 2023; y <= 2026; y++) isDate(y, 3, 1),
    ]);
    expect(draft.payments.map((p) => (p.amountMinor, p.currency)).toSet(), {
      (9999, 'USD'),
    });
  });

  test('a start on the 31st clamps to month ends without drifting', () {
    final draft = draftOf(
      tillaRecord('eom', {
        'billingDate': midnight(2026, 1, 31),
        'nextBillDate': midnight(2026, 5, 31),
      }),
    );
    expect(paymentDates(draft), [
      isDate(2026, 1, 31),
      isDate(2026, 2, 28),
      isDate(2026, 3, 31),
      isDate(2026, 4, 30),
    ]);
  });

  test('a past endDate cancels and stops payments before that day', () {
    final draft = draftOf(
      tillaRecord('gone', {
        'billingDate': midnight(2025, 1, 10),
        'nextBillDate': midnight(2026, 11, 10),
        'endDate': midnight(2025, 6, 10),
      }),
    );
    expect(draft.status, SubscriptionStatus.cancelled);
    expect(draft.endDate, isDate(2025, 6, 10));
    expect(paymentDates(draft), [
      for (var m = 1; m <= 5; m++) isDate(2025, m, 10),
    ]);
  });

  test('a future endDate means ending; payments still stop at today', () {
    final draft = draftOf(
      tillaRecord('soon', {'endDate': midnight(2026, 12, 1)}),
    );
    expect(draft.status, SubscriptionStatus.ending);
    expect(draft.payments, hasLength(9));
  });

  test('a payment due today counts; nextBillDate bounds a stale export', () {
    final due = draftOf(
      tillaRecord('due', {
        'billingDate': midnight(2026, 8, 11),
        'nextBillDate': midnight(2026, 11, 11),
      }),
    );
    expect(paymentDates(due).last, isDate(2026, 10, 11));
    final stale = draftOf(
      tillaRecord('stale', {
        'billingDate': midnight(2026, 1, 5),
        'nextBillDate': midnight(2026, 4, 5),
      }),
    );
    expect(stale.nextDate, isDate(2026, 4, 5));
    expect(paymentDates(stale), [
      for (var m = 1; m <= 3; m++) isDate(2026, m, 5),
    ]);
  });

  test('an endDate of today is still ending', () {
    final draft = draftOf(
      tillaRecord('today', {'endDate': midnight(2026, 10, 11)}),
    );
    expect(draft.status, SubscriptionStatus.ending);
  });

  test('suspended is paused whatever the endDate', () {
    final draft = draftOf(
      tillaRecord('nap', {
        'isSuspended': true,
        'endDate': midnight(2025, 1, 1),
        'paymentTracking': 'MANUAL',
      }),
    );
    expect(draft.status, SubscriptionStatus.paused);
    expect(draft.autoRenew, isFalse);
  });

  test('one-time: a single payment on the purchase day, which has a time', () {
    // 本地 3 月 11 日 07:30（UTC+8）在 UTC 里是 3 月 10 日 23:30。
    final bought = midnight(2026, 3, 11) + 450 * 60 * 1000;
    final parsed = parseAtToday(
      tillaExport([
        tillaRecord('anchor'),
        tillaRecord('lifetime', {
          'isOneTime': true,
          'billingCycle': 'garbage',
          'billingDate': bought,
          'nextBillDate': bought,
          'price': 128,
        }),
      ]),
    );
    final draft = parsed.drafts.last;
    expect(draft.kind, SubscriptionKind.oneTime);
    expect(draft.cycle, isNull);
    expect(draft.startDate, isDate(2026, 3, 11));
    expect(draft.nextDate, isNull);
    expect(draft.autoRenew, isFalse);
    expect(paymentDates(draft), [isDate(2026, 3, 11)]);
    expect(draft.payments.single.amountMinor, 12800);
    expect(draft.warnings, isEmpty);
  });

  test('a one-time purchase dated after today has no payment yet', () {
    final later = midnight(2026, 12, 1) + 3600 * 1000;
    final parsed = parseAtToday(
      tillaExport([
        tillaRecord('anchor'),
        tillaRecord('preorder', {
          'isOneTime': true,
          'billingDate': later,
          'nextBillDate': later,
        }),
      ]),
    );
    expect(parsed.drafts.last.startDate, isDate(2026, 12, 1));
    expect(parsed.drafts.last.payments, isEmpty);
  });
}
