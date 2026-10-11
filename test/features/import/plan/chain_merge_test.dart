import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/import/plan/chain_merge.dart';
import 'package:ebb/features/import/plan/import_ids.dart';
import 'package:ebb/features/import/plan/plan_item.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_drafts.dart';

List<(String, int)> datesAndAmounts(List<PlannedPayment> payments) => [
  for (final p in payments) (p.date.isoDate, p.amountMinor),
];

void main() {
  final jan1 = utcDate(2025, 1, 1);
  final feb1 = utcDate(2025, 2, 1);

  test('the body is the last record, with every label and warning', () {
    final a = closedDraft(
      'a',
      jan1,
    ).copyWith(labels: ['Video'], notes: 'old plan');
    final b = fakeDraft('b', start: feb1, priceMinor: 1800, labels: ['Fun']);
    final body = mergedBody([a, b]);
    expect(body.sourceId, 'b');
    expect(body.priceMinor, 1800);
    expect(body.status, SubscriptionStatus.active);
    expect(body.notes, isNull);
    expect(body.labels, ['Video', 'Fun']);
    expect(body.payments, isEmpty);
  });

  test('an earlier record without an end is paid until its successor, '
      'at its own price', () {
    // 暂停、无结束日：草稿里的付款一直补到 6 月，合并后只保留到后继开始前。
    final a = fakeDraft(
      'a',
      start: jan1,
      priceMinor: 1200,
      status: SubscriptionStatus.paused,
      paidUntil: utcDate(2025, 6, 1),
    );
    final b = fakeDraft('b', start: feb1, paidUntil: utcDate(2025, 4, 1));
    final payments = plannedPayments([a, b]);
    expect(datesAndAmounts(payments), [
      ('2025-01-01', 1200),
      ('2025-02-01', 1500),
      ('2025-03-01', 1500),
    ]);
    expect(payments.first.origin, PaymentOrigin.backfilled);
    expect(payments.first.id, importedPaymentId(a, jan1));
    expect(payments[1].id, importedPaymentId(b, feb1));
  });

  test('a successor starting late within tolerance does not give the '
      'earlier record a near-duplicate period', () {
    final a = closedDraft('a', jan1);
    final b = fakeDraft('b', start: utcDate(2025, 2, 4));
    expect(datesAndAmounts(plannedPayments([a, b])), [
      ('2025-01-01', 1500),
      ('2025-02-04', 1500),
    ]);
  });

  test('an earlier record with a known end keeps its own payments', () {
    final a = fakeDraft(
      'a',
      start: jan1,
      end: utcDate(2025, 1, 20),
      status: SubscriptionStatus.cancelled,
      priceMinor: 900,
    );
    final b = fakeDraft('b', start: feb1);
    expect(datesAndAmounts(plannedPayments([a, b])), [
      ('2025-01-01', 900),
      ('2025-02-01', 1500),
    ]);
  });

  test('three yearly records keep each year at its own price', () {
    final records = [
      fakeDraft(
        'a',
        cycle: yearly,
        start: utcDate(2023, 1, 1),
        priceMinor: 10000,
        status: SubscriptionStatus.cancelled,
        endDateUnknown: true,
      ),
      fakeDraft(
        'b',
        cycle: yearly,
        start: utcDate(2024, 1, 3),
        priceMinor: 12000,
        status: SubscriptionStatus.cancelled,
        endDateUnknown: true,
      ),
      fakeDraft('c', cycle: yearly, start: jan1, priceMinor: 15000),
    ];
    expect(datesAndAmounts(plannedPayments(records)), [
      ('2023-01-01', 10000),
      ('2024-01-03', 12000),
      ('2025-01-01', 15000),
    ]);
    // 只有前面记录的「结束日期未知」由后继补上；最后一条保持自己的值。
    expect(mergedBody(records).endDateUnknown, isFalse);
  });

  test('a single record keeps its payments', () {
    final payments = plannedPayments([
      fakeDraft('a', start: jan1, paidUntil: utcDate(2025, 3, 15)),
    ]);
    expect(payments.map((p) => p.date.isoDate), [
      '2025-01-01',
      '2025-02-01',
      '2025-03-01',
    ]);
  });
}
