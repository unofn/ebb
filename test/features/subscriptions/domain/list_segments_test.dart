import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/subscriptions/domain/list_segments.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  final later = fakeSubscription(id: 'later', nextDate: utcDate(2026, 11, 1));
  final soonB = fakeSubscription(
    id: 'soonB',
    name: 'B',
    nextDate: utcDate(2026, 10, 20),
  );
  final soonA = soonB.copyWith(id: 'soonA', name: 'A');
  final ending = later.copyWith(
    id: 'ending',
    status: SubscriptionStatus.ending,
  );
  final paused = later.copyWith(
    id: 'paused',
    status: SubscriptionStatus.paused,
  );
  final noNext = later.copyWith(id: 'noNext', nextDate: const Value(null));
  final cancelled = later.copyWith(
    id: 'cancelled',
    status: SubscriptionStatus.cancelled,
  );
  final oneTime = later.copyWith(id: 'oneTime', kind: SubscriptionKind.oneTime);
  final deleted = later.copyWith(id: 'deleted', deleted: true);
  final subs = [
    later,
    soonB,
    soonA,
    ending,
    paused,
    noNext,
    cancelled,
    oneTime,
    deleted,
  ];

  List<String> idsIn(ListSegment segment) =>
      subscriptionsIn(segment, subs).map((s) => s.id).toList();

  test('upcoming: active or ending with a next date, by date then name', () {
    expect(idsIn(ListSegment.upcoming), ['soonA', 'soonB', 'later', 'ending']);
  });

  test('all: recurring and not cancelled, input order', () {
    expect(idsIn(ListSegment.all), [
      'later',
      'soonB',
      'soonA',
      'ending',
      'paused',
      'noNext',
    ]);
  });

  test('one-time and archived; deleted nowhere', () {
    expect(idsIn(ListSegment.oneTime), ['oneTime']);
    expect(idsIn(ListSegment.archived), ['cancelled']);
  });
}
