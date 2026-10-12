import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/stats/domain/monthly_exclusions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  final today = utcDate(2026, 10, 12);

  test('lists running subscriptions left out of the average, by name', () {
    final subs = [
      fakeSubscription(id: 'a', name: 'Active'),
      fakeSubscription(
        id: 'k',
        name: 'Keep',
      ).copyWith(trialEndsOn: Value(utcDate(2026, 10, 18))),
      fakeSubscription(id: 'j', name: 'jd', status: SubscriptionStatus.ending),
      fakeSubscription(id: 'p', name: 'Gym', status: SubscriptionStatus.paused),
      fakeSubscription(id: 'r', name: 'Work').copyWith(reimbursed: true),
      fakeSubscription(
        id: 'c',
        name: 'Old',
        status: SubscriptionStatus.cancelled,
      ),
      fakeSubscription(id: 'n', name: 'NoCycle', cycleUnit: null),
    ];
    expect(
      [for (final e in monthlyExclusions(subs, today)) (e.sub.id, e.reason)],
      [
        ('p', ExclusionReason.paused),
        ('j', ExclusionReason.ending),
        ('k', ExclusionReason.trial),
        ('r', ExclusionReason.reimbursed),
      ],
    );
  });

  test('one-time purchases and deleted rows are not listed', () {
    final once = fakeSubscription(status: SubscriptionStatus.paused)
        .copyWith(kind: SubscriptionKind.oneTime);
    final deleted = fakeSubscription(status: SubscriptionStatus.paused)
        .copyWith(deleted: true);
    expect(monthlyExclusions([once, deleted], today), isEmpty);
  });
}
