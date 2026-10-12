import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/calendar/domain/calendar_charge.dart';
import 'package:ebb/features/calendar/domain/charges_in_month.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';
import '../../../support/fake_rows.dart';

void main() {
  final today = utcDate(2026, 10, 12);

  CalendarCharge charge(String id, int minor, ChargeKind kind) =>
      CalendarCharge(
        subscriptionId: id,
        amountMinor: minor,
        currency: 'CNY',
        kind: kind,
      );

  final video = fakeSubscription(
    id: 'video',
    name: 'Video',
    startDate: utcDate(2026, 1, 3),
    nextDate: utcDate(2026, 11, 3),
  );
  final music = fakeSubscription(
    id: 'music',
    name: 'Music',
    priceMinor: 1500,
    autoRenew: false,
    startDate: utcDate(2026, 8, 10),
    nextDate: utcDate(2026, 10, 10),
  );
  final payments = [
    fakePayment('p1', 'video', utcDate(2026, 10, 3), 1200),
    fakePayment('p0', 'video', utcDate(2026, 9, 3), 1200),
    fakePayment('px', 'video', utcDate(2026, 10, 4), 1200, deleted: true),
    fakePayment('po', 'removed', utcDate(2026, 10, 5), 999),
  ];
  final removed = fakeSubscription(id: 'removed').copyWith(deleted: true);

  test('paid up to today, awaiting confirmation, expected after', () {
    final days = chargesInMonth(
      2026,
      10,
      payments: payments,
      subs: [video, music, removed],
      today: today,
    );
    expect(days, {
      3: [charge('video', 1200, ChargeKind.paid)],
      10: [charge('music', 1500, ChargeKind.awaitingConfirmation)],
    });
  });

  test('later months are projected, the overdue manual one included', () {
    final days = chargesInMonth(
      2026,
      11,
      payments: payments,
      subs: [video, music],
      today: today,
    );
    expect(days, {
      3: [charge('video', 1200, ChargeKind.expected)],
      10: [charge('music', 1500, ChargeKind.expected)],
    });
  });

  test('a charge confirmed ahead of its date shows as paid, once', () {
    final early = music.copyWith(nextDate: Value(utcDate(2026, 11, 10)));
    final days = chargesInMonth(
      2026,
      10,
      payments: [fakePayment('m', 'music', utcDate(2026, 10, 20), 1500)],
      subs: [early],
      today: today,
    );
    expect(days, {
      20: [charge('music', 1500, ChargeKind.paid)],
    });
  });

  test('one day lists kinds in order, then names', () {
    final day3 = utcDate(2026, 11, 3);
    final day20 = utcDate(2026, 11, 20);
    DateTime jan(int day) => utcDate(2026, 1, day);
    final subs = [
      fakeSubscription(id: 'video', name: 'Video', startDate: jan(3)),
      fakeSubscription(
        id: 'alpha',
        name: 'Alpha',
        autoRenew: false,
        startDate: jan(3),
        nextDate: day3,
      ),
      fakeSubscription(
        id: 'zeta',
        name: 'Zeta',
        autoRenew: false,
        startDate: jan(20),
        nextDate: utcDate(2026, 12, 20),
      ),
      fakeSubscription(
        id: 'beta',
        name: 'Beta',
        startDate: jan(20),
        nextDate: day20,
      ),
      fakeSubscription(
        id: 'apple',
        name: 'Apple',
        startDate: jan(20),
        nextDate: day20,
      ),
      fakeSubscription(
        id: 'paused',
        status: SubscriptionStatus.paused,
        startDate: jan(20),
        nextDate: day20,
      ),
    ];
    final days = chargesInMonth(
      2026,
      11,
      payments: [
        fakePayment('v', 'video', day3, 1200),
        fakePayment('z', 'zeta', day20, 1200),
      ],
      subs: subs,
      today: day3,
    );
    expect(days, {
      3: [
        charge('video', 1200, ChargeKind.paid),
        charge('alpha', 1200, ChargeKind.awaitingConfirmation),
      ],
      20: [
        charge('zeta', 1200, ChargeKind.paid),
        charge('apple', 1200, ChargeKind.expected),
        charge('beta', 1200, ChargeKind.expected),
      ],
    });
  });
}
