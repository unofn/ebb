import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sm_fixture.dart';

void main() {
  group('with expiringDate', () {
    test('future expiry: ending, no payments after today', () {
      final draft = draftOf(smRecord(5, {'expiringDate': '2026-12-15'}));
      expect(draft.status, SubscriptionStatus.ending);
      expect(draft.endDate, utcDate(2026, 12, 15));
      expect(paidOn(draft), ['2026-08-15', '2026-09-15']);
      expect(draft.nextDate, utcDate(2026, 10, 15));
      expect(draft.autoRenew, isFalse);
    });

    test('ending: no next date past the expiry', () {
      final draft = draftOf(smRecord(6, {'expiringDate': '2026-10-12'}));
      expect(draft.status, SubscriptionStatus.ending);
      expect(draft.nextDate, isNull);
    });

    test('past expiry: cancelled, the expiry day itself is not paid', () {
      final draft = draftOf(
        smRecord(7, {
          'firstBillingDate': '2026-06-15',
          'expiringDate': '2026-09-15',
        }),
      );
      expect(draft.status, SubscriptionStatus.cancelled);
      expect(paidOn(draft), ['2026-06-15', '2026-07-15', '2026-08-15']);
      expect(draft.nextDate, isNull);
      expect(draft.endDateUnknown, isFalse);
    });
  });

  group('inactive', () {
    test('without expiringDate: first payment only, end date unknown', () {
      final draft = draftOf(
        smRecord(8, {'active': false, 'firstBillingDate': '2025-01-10'}),
      );
      expect(draft.status, SubscriptionStatus.cancelled);
      expect(paidOn(draft), ['2025-01-10']);
      expect(draft.endDate, isNull);
      expect(draft.endDateUnknown, isTrue);
      expect(draft.nextDate, isNull);
      expect(draft.autoRenew, isFalse);
    });

    test('with expiringDate: cancelled, backfilled up to it, exclusive', () {
      final draft = draftOf(
        smRecord(9, {
          'active': false,
          'firstBillingDate': '2025-12-10',
          'expiringDate': '2026-03-10',
        }),
      );
      expect(draft.status, SubscriptionStatus.cancelled);
      expect(draft.endDate, utcDate(2026, 3, 10));
      expect(draft.endDateUnknown, isFalse);
      expect(paidOn(draft), ['2025-12-10', '2026-01-10', '2026-02-10']);
    });

    test(
      'with a future expiringDate: still cancelled, nothing after today',
      () {
        final draft = draftOf(
          smRecord(10, {'active': false, 'expiringDate': '2027-01-01'}),
        );
        expect(draft.status, SubscriptionStatus.cancelled);
        expect(paidOn(draft), ['2026-08-15', '2026-09-15']);
        expect(draft.nextDate, isNull);
      },
    );
  });
}
