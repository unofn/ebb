import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/billing/cycle.dart';
import 'package:ebb/features/subscriptions/domain/default_next_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = utcDate(2026, 10, 12);
  const monthly = Cycle(CycleUnit.month, 1);

  test('a past start moves to the first occurrence from today on', () {
    expect(
      defaultNextDate(
        start: utcDate(2025, 3, 22),
        cycle: monthly,
        today: today,
      ),
      utcDate(2026, 10, 22),
    );
  });

  test('an occurrence on today is today', () {
    expect(
      defaultNextDate(
        start: utcDate(2026, 8, 12),
        cycle: monthly,
        today: today,
      ),
      today,
    );
  });

  test('a future start is the start', () {
    expect(
      defaultNextDate(
        start: utcDate(2026, 11, 3),
        cycle: const Cycle(CycleUnit.year, 1),
        today: today,
      ),
      utcDate(2026, 11, 3),
    );
  });

  test('a trial counts from its end', () {
    expect(
      defaultNextDate(
        start: utcDate(2026, 10, 1),
        cycle: monthly,
        trialEndsOn: utcDate(2026, 10, 25),
        today: today,
      ),
      utcDate(2026, 10, 25),
    );
    expect(
      defaultNextDate(
        start: utcDate(2026, 1, 1),
        cycle: monthly,
        trialEndsOn: utcDate(2026, 2, 5),
        today: today,
      ),
      utcDate(2026, 11, 5),
    );
  });

  test('month ends clamp from the anchor', () {
    expect(
      defaultNextDate(
        start: utcDate(2026, 1, 31),
        cycle: monthly,
        today: utcDate(2027, 2, 1),
      ),
      utcDate(2027, 2, 28),
    );
  });
}
