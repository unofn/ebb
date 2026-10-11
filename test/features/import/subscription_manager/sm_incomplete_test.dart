import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/import/draft/import_warning.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sm_fixture.dart';

void main() {
  group('incomplete records', () {
    test('missing firstBillingDate: no payments, no next date', () {
      final draft = draftOf(smRecord(11)..remove('firstBillingDate'));
      expect(draft.startDate, isNull);
      expect(draft.payments, isEmpty);
      expect(draft.nextDate, isNull);
      expect(draft.status, SubscriptionStatus.active);
      expect(codesOf(draft), [ImportWarningCode.missingStartDate]);
    });

    test('an invalid firstBillingDate counts as missing', () {
      final draft = draftOf(smRecord(12, {'firstBillingDate': '2026-13-01'}));
      expect(draft.payments, isEmpty);
      expect(draft.warnings, [
        const ImportWarning(
          ImportWarningCode.invalidDate,
          sourceId: '12',
          detail: '2026-13-01',
        ),
        const ImportWarning(
          ImportWarningCode.missingStartDate,
          sourceId: '12',
          detail: '2026-13-01',
        ),
      ]);
    });

    test('unknown cycleRhythm: no cycle, no payments', () {
      final draft = draftOf(
        smRecord(13, {
          'cycle': {'cycleDuration': 1, 'cycleRhythm': 7, 'cycleType': 1},
        }),
      );
      expect(draft.cycle, isNull);
      expect(draft.startDate, utcDate(2026, 8, 15));
      expect(draft.payments, isEmpty);
      expect(draft.nextDate, isNull);
      expect(draft.warnings, [
        const ImportWarning(
          ImportWarningCode.unknownCycleRhythm,
          sourceId: '13',
          detail: 'rhythm 7 × 1',
        ),
      ]);
    });

    test('a non-positive cycleDuration is an unknown cycle', () {
      final draft = draftOf(
        smRecord(14, {
          'cycle': {'cycleDuration': 0, 'cycleRhythm': 2, 'cycleType': 1},
        }),
      );
      expect(draft.cycle, isNull);
      expect(codesOf(draft), [ImportWarningCode.unknownCycleRhythm]);
    });

    test('duration other than -1 warns but imports as usual', () {
      final draft = draftOf(smRecord(15, {'duration': 12}));
      expect(draft.payments, hasLength(2));
      expect(draft.warnings, [
        const ImportWarning(
          ImportWarningCode.unexpectedDuration,
          sourceId: '15',
          detail: '12',
        ),
      ]);
    });
  });
}
