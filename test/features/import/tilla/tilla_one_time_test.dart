import 'package:ebb/data/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_tilla.dart';

void main() {
  test('one-time with an endDate: no end date, kept in notes, active', () {
    // 时区只从周期订阅推断；放一条周期订阅把来源钉在 UTC+8，不随本机时区变。
    final drafts = parseAtToday(
      tillaExport([
        tillaRecord('once', {
          'isOneTime': true,
          'billingDate': midnight(2024, 3, 2) + 15 * 3600 * 1000,
          'nextBillDate': midnight(2024, 3, 2) + 15 * 3600 * 1000,
          'endDate': midnight(2025, 3, 2),
          'notes': '假的授权',
        }),
        tillaRecord('anchor'),
      ]),
    ).drafts;
    final draft = drafts.firstWhere((d) => d.sourceId == 'once');
    expect(draft.kind, SubscriptionKind.oneTime);
    expect(draft.endDate, isNull);
    expect(draft.status, SubscriptionStatus.active);
    expect(draft.notes, '假的授权\n原到期日 2025-03-02');
    expect(paymentDates(draft), [isDate(2024, 3, 2)]);
  });

  test('one-time without an endDate keeps notes as they are', () {
    final draft = draftOf(
      tillaRecord('plain', {
        'isOneTime': true,
        'billingDate': midnight(2024, 3, 2),
        'notes': null,
      }),
    );
    expect(draft.notes, isNull);
  });
}
