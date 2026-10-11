import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/billing/cycle.dart';
import 'package:ebb/features/billing/monthly_cost.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('monthlyMinor', () {
    test('year ÷ 12×count, month ÷ count', () {
      expect(monthlyMinor(12000, Cycle(CycleUnit.year, 1)), 1000);
      expect(monthlyMinor(12000, Cycle(CycleUnit.year, 2)), 500);
      expect(monthlyMinor(3000, Cycle(CycleUnit.month, 1)), 3000);
      expect(monthlyMinor(6000, Cycle(CycleUnit.month, 6)), 1000);
    });

    test('week and day use 365.2425 days a year, rounded', () {
      // 700 × 365.2425 / 7 / 12 = 3043.6875
      expect(monthlyMinor(700, Cycle(CycleUnit.week, 1)), 3044);
      expect(monthlyMinor(700, Cycle(CycleUnit.week, 2)), 1522);
      // 100 × 365.2425 / 12 = 3043.6875
      expect(monthlyMinor(100, Cycle(CycleUnit.day, 1)), 3044);
    });
  });

  group('countsTowardMonthly and monthlyCostOf', () {
    final today = utcDate(2026, 10, 11);
    final base = Subscription(
      id: 's1',
      updatedAt: '',
      deleted: false,
      name: 'Video',
      kind: SubscriptionKind.recurring,
      priceMinor: 1200,
      currency: 'CNY',
      cycleUnit: CycleUnit.month,
      cycleCount: 1,
      endDateUnknown: false,
      status: SubscriptionStatus.active,
      autoRenew: true,
      reminderEnabled: false,
      reimbursed: false,
    );

    test('an active recurring subscription counts', () {
      expect(countsTowardMonthly(base, today), isTrue);
      expect(monthlyCostOf(base, today), 1200);
    });

    test('excluded states', () {
      final excluded = {
        'one-time': base.copyWith(kind: SubscriptionKind.oneTime),
        'paused': base.copyWith(status: SubscriptionStatus.paused),
        'ending': base.copyWith(status: SubscriptionStatus.ending),
        'cancelled': base.copyWith(status: SubscriptionStatus.cancelled),
        'reimbursed': base.copyWith(reimbursed: true),
        'deleted': base.copyWith(deleted: true),
        'no cycle': base.copyWith(cycleUnit: const Value(null)),
        'trial ends later': base.copyWith(
          trialEndsOn: Value(utcDate(2026, 11, 1)),
        ),
      };
      for (final MapEntry(:key, :value) in excluded.entries) {
        expect(countsTowardMonthly(value, today), isFalse, reason: key);
        expect(monthlyCostOf(value, today), isNull, reason: key);
      }
    });

    test('a trial ending today or before counts', () {
      for (final end in [today, utcDate(2026, 10, 10)]) {
        final sub = base.copyWith(trialEndsOn: Value(end));
        expect(countsTowardMonthly(sub, today), isTrue, reason: '$end');
      }
    });

    test('shared uses my share; intro offer uses the regular price', () {
      final shared = base.copyWith(
        priceMinor: 9000,
        cycleUnit: const Value(CycleUnit.year),
        myShareMinor: const Value(3000),
      );
      expect(monthlyCostOf(shared, today), 250);
      final intro = base.copyWith(
        introPriceMinor: const Value(100),
        introEndsOn: Value(utcDate(2026, 12, 1)),
      );
      expect(monthlyCostOf(intro, today), 1200);
    });
  });
}
