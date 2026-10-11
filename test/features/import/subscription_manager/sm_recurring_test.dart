import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/billing/cycle.dart';
import 'package:ebb/features/import/draft/import_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sm_fixture.dart';

void main() {
  group('active without expiringDate', () {
    test('backfills up to today and schedules the next date', () {
      final draft = draftOf(smRecord(1, {'firstBillingDate': '2026-07-11'}));
      expect(draft.kind, SubscriptionKind.recurring);
      expect(draft.cycle, const Cycle(CycleUnit.month, 1));
      expect(draft.startDate, utcDate(2026, 7, 11));
      expect(paidOn(draft), [
        '2026-07-11',
        '2026-08-11',
        '2026-09-11',
        '2026-10-11', // 今天这一期计入
      ]);
      expect(
        draft.payments.first,
        DraftPayment(
          date: utcDate(2026, 7, 11),
          amountMinor: 2500,
          currency: 'CNY',
          origin: PaymentOrigin.backfilled,
        ),
      );
      expect(draft.nextDate, utcDate(2026, 11, 11));
      expect(draft.status, SubscriptionStatus.active);
      expect(draft.autoRenew, isTrue);
      expect(draft.endDate, isNull);
      expect(draft.endDateUnknown, isFalse);
      expect(draft.warnings, isEmpty);
    });

    test('every 6 months from a month end clamps without drifting', () {
      final draft = draftOf(
        smRecord(2, {
          'firstBillingDate': '2025-08-31',
          'cycle': {'cycleDuration': 6, 'cycleRhythm': 2, 'cycleType': 1},
        }),
      );
      expect(draft.cycle, const Cycle(CycleUnit.month, 6));
      // 2026 不是闰年：2 月夹紧到 28 日，8 月回到 31 日。
      expect(paidOn(draft), ['2025-08-31', '2026-02-28', '2026-08-31']);
      expect(draft.nextDate, utcDate(2027, 2, 28));
    });

    test('maps every Calendar rhythm seen for cycles', () {
      Cycle? cycleOf(int rhythm) => draftOf(
        smRecord(3, {
          'cycle': {'cycleDuration': 2, 'cycleRhythm': rhythm, 'cycleType': 1},
        }),
      ).cycle;
      expect(cycleOf(1), const Cycle(CycleUnit.year, 2));
      expect(cycleOf(2), const Cycle(CycleUnit.month, 2));
      expect(cycleOf(3), const Cycle(CycleUnit.week, 2));
      expect(cycleOf(4), const Cycle(CycleUnit.week, 2));
      expect(cycleOf(5), const Cycle(CycleUnit.day, 2));
      expect(cycleOf(6), const Cycle(CycleUnit.day, 2));
    });

    test('a future start has no payments yet', () {
      final draft = draftOf(smRecord(4, {'firstBillingDate': '2026-11-01'}));
      expect(draft.payments, isEmpty);
      expect(draft.nextDate, utcDate(2026, 11, 1));
    });
  });
}
