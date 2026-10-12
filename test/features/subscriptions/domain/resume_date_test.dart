import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/subscriptions/domain/resume_date.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  final today = utcDate(2026, 10, 12);

  test('the first charge on or after today, counted from the start', () {
    final sub = fakeSubscription(
      startDate: utcDate(2026, 1, 31),
      nextDate: utcDate(2026, 3, 31),
      status: SubscriptionStatus.cancelled,
    );
    expect(resumeDateOf(sub, today), utcDate(2026, 10, 31));
    expect(resumeDateOf(sub, utcDate(2026, 10, 31)), utcDate(2026, 10, 31));
  });

  test('a next date still today or later stays, even off the grid', () {
    final paused = fakeSubscription(
      startDate: utcDate(2026, 1, 31),
      nextDate: utcDate(2026, 11, 3),
      status: SubscriptionStatus.paused,
    );
    expect(resumeDateOf(paused, today), utcDate(2026, 11, 3));
    expect(resumeDateOf(paused.copyWith(nextDate: Value(today)), today), today);
    expect(
      resumeDateOf(paused.copyWith(cycleUnit: const Value(null)), today),
      utcDate(2026, 11, 3),
      reason: 'kept without a cycle too',
    );
  });

  test('a next date already past moves to the first charge from today', () {
    final paused = fakeSubscription(
      startDate: utcDate(2026, 1, 31),
      nextDate: utcDate(2026, 10, 11),
      status: SubscriptionStatus.paused,
    );
    expect(resumeDateOf(paused, today), utcDate(2026, 10, 31));
  });

  test('without a next date counts from the start', () {
    final paused = fakeSubscription(
      startDate: utcDate(2026, 1, 31),
      status: SubscriptionStatus.paused,
    );
    expect(resumeDateOf(paused, today), utcDate(2026, 10, 31));
  });

  test('without a start date counts from the next date', () {
    final sub = fakeSubscription(
      cycleUnit: CycleUnit.year,
      nextDate: utcDate(2024, 3, 2),
    );
    expect(resumeDateOf(sub, today), utcDate(2027, 3, 2));
  });

  test('a start after today is the first charge', () {
    final sub = fakeSubscription(startDate: utcDate(2026, 11, 5));
    expect(resumeDateOf(sub, today), utcDate(2026, 11, 5));
  });

  test('a past trial end anchors the charges like automatic payments', () {
    final sub = fakeSubscription(startDate: utcDate(2026, 1, 1))
        .copyWith(trialEndsOn: Value(utcDate(2026, 1, 8)));
    expect(resumeDateOf(sub, today), utcDate(2026, 11, 8));
  });

  test('null without a cycle or any date', () {
    expect(resumeDateOf(fakeSubscription(), today), isNull);
    expect(
      resumeDateOf(
        fakeSubscription(cycleUnit: null, startDate: utcDate(2026, 1, 1)),
        today,
      ),
      isNull,
    );
  });
}
