import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/import/draft/import_warning.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sm_fixture.dart';

/// A one-time purchase; SubscriptionManager still stores a cycle on it.
Map<String, Object?> oneTime(
  int id, [
  Map<String, Object?> overrides = const {},
]) => smRecord(id, {'type': 1, ...overrides});

void main() {
  test('with firstBillingDate: one payment, no cycle or next date', () {
    final draft = draftOf(oneTime(1, {'firstBillingDate': '2025-06-18'}));
    expect(draft.kind, SubscriptionKind.oneTime);
    expect(draft.cycle, isNull);
    expect(draft.startDate, utcDate(2025, 6, 18));
    expect(paidOn(draft), ['2025-06-18']);
    expect(draft.payments.single.amountMinor, 2500);
    expect(draft.nextDate, isNull);
    expect(draft.endDate, isNull);
    expect(draft.status, SubscriptionStatus.active);
    expect(draft.autoRenew, isFalse);
    expect(draft.warnings, isEmpty);
  });

  test('with both dates: expiringDate is the end date', () {
    final draft = draftOf(
      oneTime(2, {
        'firstBillingDate': '2025-06-18',
        'expiringDate': '2026-06-18',
      }),
    );
    expect(paidOn(draft), ['2025-06-18']);
    expect(draft.endDate, utcDate(2026, 6, 18));
    expect(draft.endDateUnknown, isFalse);
  });

  test('no dates at all: no payment, warns', () {
    final draft = draftOf(oneTime(3)..remove('firstBillingDate'));
    expect(draft.startDate, isNull);
    expect(draft.payments, isEmpty);
    expect(codesOf(draft), [ImportWarningCode.noDates]);
  });

  test('only expiringDate and no paymentMethod: used as purchase date', () {
    final draft = draftOf(
      oneTime(4, {'expiringDate': '2026-05-20'})
        ..remove('firstBillingDate')
        ..remove('paymentMethod'),
    );
    expect(draft.startDate, utcDate(2026, 5, 20));
    expect(paidOn(draft), ['2026-05-20']);
    expect(draft.endDate, isNull);
    expect(draft.paymentMethod, isNull);
    expect(draft.warnings, [
      const ImportWarning(
        ImportWarningCode.expiryAsPurchaseDate,
        sourceId: '4',
        detail: '2026-05-20',
      ),
    ]);
  });

  test('inactive: cancelled, end date not marked unknown', () {
    final draft = draftOf(oneTime(5, {'active': false}));
    expect(draft.status, SubscriptionStatus.cancelled);
    expect(draft.endDateUnknown, isFalse);
    expect(paidOn(draft), ['2026-08-15']);
  });

  test('a future purchase date records no payment yet', () {
    final draft = draftOf(oneTime(6, {'firstBillingDate': '2026-12-01'}));
    expect(draft.startDate, utcDate(2026, 12, 1));
    expect(draft.payments, isEmpty);
  });
}
